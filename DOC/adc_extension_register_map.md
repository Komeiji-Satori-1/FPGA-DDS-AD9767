# AD9226 扩展寄存器表草案

## 1. SPI 帧格式

沿用现有工程的 40 bit SPI 帧：

```text
[ CMD 8-bit ][ DATA 32-bit ]
```

`CMD` 定义：

```text
bit7      RW
          0 = write
          1 = read

bit6:5    TARGET
          00 = CH A
          01 = CH B
          10 = GLOBAL
          11 = ADC ACQ

bit4:0    ADDR
          register address
```

说明：
- 现有 DAC 相关目标保持不变
- 新增 `TARGET=11` 作为 ADC 采集子系统

## 2. ADC 采集寄存器

`TARGET = 11`。

| ADDR | 名称 | 读写 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| 0x00 | ACQ_CTRL | R/W | 0x00000000 | 采集总控制 |
| 0x01 | CH_ENABLE | R/W | 0x00000003 | 通道使能 |
| 0x02 | SAMPLE_CFG | R/W | 0x00000032 | 采样时钟配置，初始对应 1 MHz |
| 0x03 | FRAME_LEN | R/W | 0x00000400 | 帧长，默认 1024 |
| 0x04 | READ_MODE | R/W | 0x00000001 | 回传顺序与数据模式 |
| 0x05 | IRQ_MASK | R/W | 0x00000001 | 中断屏蔽 |
| 0x06 | IRQ_STATUS | R/W1C | 0x00000000 | 中断状态，写 1 清除 |
| 0x07 | ERROR_STATUS | R/W1C | 0x00000000 | 错误状态，写 1 清除 |
| 0x08 | BUFFER_LEVEL | R | 0x00000000 | 当前缓存深度 |
| 0x09 | SAMPLE_COUNT | R | 0x00000000 | 当前帧计数 |
| 0x0A | FFT_CTRL | R/W | 0x00000000 | FFT 预留控制 |
| 0x0B | FFT_STATUS | R/W1C | 0x00000000 | FFT 预留状态 |

## 3. ACQ_CTRL 定义

```text
bit0      acq_enable
          0 = stop
          1 = start

bit1      one_shot
          0 = continuous
          1 = capture one frame only

bit2      soft_reset
          写 1 触发采集子系统软复位

bit3      clear_fifo
          写 1 清空缓冲

bit4      irq_enable
          0 = 禁止中断
          1 = 允许中断

bit5      ch1_first
          0 = 固定 CH1 -> CH2
          1 = 预留

bit6      raw_enable
          1 = 允许原始数据回传

bit7      fft_enable
          1 = 允许 FFT 路径

bit31:8   reserved
```

## 4. CH_ENABLE 定义

```text
bit0      ch1_enable
bit1      ch2_enable
bit31:2   reserved
```

说明：
- 双路同时采集时，`bit0=1` 且 `bit1=1`
- 单路采集时，仅置位对应通道

## 5. SAMPLE_CFG 定义

建议预留为采样时钟配置字，初版定义如下：

```text
bit15:0   sample_div
          采样时钟分频或等效配置

bit31:16  sample_clk_khz
          目标采样时钟频率，单位 kHz
```

初始默认：
- `sample_clk_khz = 1000`

说明：
- 如果后续采样时钟由 PLL 固定生成，可以把其中一部分字段改为只读状态镜像
- 这一项的最终实现要结合板级时钟与 AD9226 时序余量确认

## 6. FRAME_LEN 定义

```text
bit15:0   frame_len
          默认 1024

bit31:16  reserved
```

## 7. READ_MODE 定义

```text
bit0      sequence_mode
          0 = CH1 先回传，CH2 后回传
          1 = 预留

bit1      packet_mode
          0 = 逐样本回传
          1 = 打包回传

bit2      include_index
          1 = 回传样本序号

bit3      include_channel_id
          1 = 回传通道标识

bit31:4   reserved
```

第一版建议：
- `sequence_mode = 0`
- `packet_mode = 0`
- `include_index = 1`
- `include_channel_id = 1`

## 8. IRQ_STATUS 定义

```text
bit0      frame_ready
bit1      raw_block_ready
bit2      fft_ready
bit3      overflow
bit4      underflow
bit5      config_error
bit6      adc_misaligned
bit7      reserved
bit31:8   reserved
```

说明：
- 中断线 `IRQ` 拉高后，MCU 读该寄存器确定原因
- 采用写 1 清除方式

## 9. ERROR_STATUS 定义

```text
bit0      fifo_overflow
bit1      fifo_underflow
bit2      adc_clk_loss
bit3      sample_misaligned
bit4      spi_frame_error
bit5      reserved
bit31:6   reserved
```

## 10. 数据回传格式

建议第一版使用 32 bit 读出包：

```text
bit31:20  sample_index
bit19     channel_id
bit18     frame_last
bit17     valid
bit16     sign_or_reserved
bit15:4   sample_data[11:0]
bit3:0    reserved
```

规则：
- CH1 先读完，再读 CH2
- 每帧 1024 点
- MCU 读取时以 `IRQ_STATUS.frame_ready` 为开始条件

## 11. FFT 预留寄存器

```text
FFT_CTRL
  bit0  fft_start
  bit1  fft_clear
  bit2  fft_mode
  bit3  window_enable
  bit4  magnitude_enable
  bit31:5 reserved

FFT_STATUS
  bit0  fft_busy
  bit1  fft_done
  bit2  fft_error
  bit31:3 reserved
```

说明：
- 第一版可以只保留寄存器，不接真实 FFT 运算
- 后续接入 FFT 模块时不需要改 MCU 协议
