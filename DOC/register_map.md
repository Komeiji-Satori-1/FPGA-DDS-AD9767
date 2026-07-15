# SPI 寄存器映射草案

## 1. SPI 基本约定

建议使用：

```text
SPI Mode 0
CPOL = 0
CPHA = 0
MSB first
CS_N low active
```

第一版使用固定 40-bit 帧：

```text
[ CMD 8-bit ][ DATA 32-bit ]
```

## 2. CMD 字段定义

```text
bit7      RW
          0 = write
          1 = read

bit6:5    TARGET
          00 = CH A
          01 = CH B
          10 = GLOBAL
          11 = reserved

bit4:0    ADDR
          register address
```

写操作：

```text
MCU -> FPGA: CMD + DATA32
FPGA -> MCU: 可返回 0 或上一帧读数据
```

读操作：

```text
MCU -> FPGA: CMD + DUMMY32
FPGA -> MCU: 返回对应寄存器值
```

第一版采用同一帧返回：读数据在同一帧的 DATA 阶段移出。

## 3. 通道寄存器

每个通道独立拥有以下寄存器。`TARGET=00` 表示 CH A，`TARGET=01` 表示 CH B。

| ADDR | 名称 | 读写 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| 0x00 | CTRL | R/W | 0x00000000 | 通道控制 |
| 0x01 | FREQ_WORD | R/W | 0x00000000 | 32-bit DDS 频率控制字 |
| 0x02 | PHASE_INIT | R/W | 0x00000000 | 32-bit 初相位 |
| 0x03 | AMP_SCALE | R/W | 0x00003FFF | 预留，幅度控制 |
| 0x04 | DC_OFFSET | R/W | 0x00002000 | 预留，直流偏置 |

## 4. CTRL 寄存器定义

```text
bit0      enable
          0 = disable
          1 = enable

bit2:1    wave_sel
          00 = sine
          01 = square
          10 = triangle
          11 = custom / reserved

bit3      phase_reset
          写 1 请求相位累加器复位，具体是否自清零由 RTL 实现决定

bit4      update_pending
          预留，用于同步更新

bit31:5   reserved
```

## 5. 全局寄存器

`TARGET=10` 表示 GLOBAL。

| ADDR | 名称 | 读写 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| 0x00 | GLOBAL_CTRL | R/W | 0x00000000 | 全局控制 |
| 0x01 | VERSION | R | 0x00010000 | 固件版本，第一版建议为 1.0.0 |
| 0x02 | STATUS | R | 0x00000000 | 状态寄存器 |

## 6. GLOBAL_CTRL 寄存器定义

```text
bit0      global_enable
          0 = all outputs disabled
          1 = outputs follow channel enable

bit1      sync_update
          预留，未来用于双通道同步加载配置

bit2      key_ctrl_enable
          0 = 按键控制关闭
          1 = 按键控制开启

bit31:3   reserved
```

## 7. STATUS 寄存器建议

```text
bit0      spi_frame_error
bit1      reserved
bit31:2   reserved
```

## 8. 频率字计算

DDS 输出频率公式：

```text
Fout = Fword * Fclk / 2^32
Fword = Fout * 2^32 / Fclk
```

如果 `Fclk = 100 MHz`：

```text
10 kHz  -> Fword ≈ 429497
50 kHz  -> Fword ≈ 2147484
```

注意：最终 `Fclk` 以 PLL 实际输出的 DDS/DAC 时钟为准。

## 9. 示例配置

目标：

```text
CH A: 10 kHz triangle
CH B: 50 kHz sine
```

假设 `Fclk = 100 MHz`：

```text
Write CH A FREQ_WORD  = 429497
Write CH A PHASE_INIT = 0
Write CH A CTRL       = enable=1, wave_sel=triangle

Write CH B FREQ_WORD  = 2147484
Write CH B PHASE_INIT = 0
Write CH B CTRL       = enable=1, wave_sel=sine

Write GLOBAL_CTRL     = global_enable=1
```

## 10. 待确认问题

1. `phase_reset` 是保持型位还是写 1 触发后自清零。
2. 第一版是否需要实现 `AMP_SCALE` 和 `DC_OFFSET`，还是只预留寄存器。
