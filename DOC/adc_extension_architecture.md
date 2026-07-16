# AD9226 采集扩展架构草案

## 1. 目标

在现有 `fpga-dac-awg` 工程中加入 AD9226 双路采集能力，形成一套可由 MCU 配置、由 FPGA 执行采样与缓存、并向 MCU 回传结果的数据采集链路。

第一版目标：
- 双路同时采集
- 任意一路可单独使能
- 默认采样率 1 MHz
- 每帧 1024 点
- MCU 通过 SPI 下发配置
- FPGA 通过中断通知 MCU
- 原始数据可回传 MCU
- FFT / DFT 预留接口

## 2. 产品边界

### 必做

- CH1 / CH2 双路同时采样
- 单路使能
- 采样参数可由 MCU 动态配置
- 1024 点分帧
- 帧完成后拉起中断
- CH1 先回传，CH2 后回传

### 预留

- FFT / DFT 计算接口
- 特征量回传接口
- 连续采样与单次采样模式
- 触发采样模式
- 预处理接口，例如去直流、窗函数、抽取

## 3. 推荐数据流

```text
MCU
  -> SPI 配置
  -> 寄存器文件
  -> 采样控制
  -> AD9226 时钟生成
  -> AD9226 双路采样数据
  -> 采样寄存器 / FIFO
  -> 1024 点帧缓存
  -> MCU 读取原始数据
  -> FFT / DFT 预留路径
```

## 4. 模块划分

### 顶层

- `wavegen_top.v`
  - 保留现有 DAC DDS 逻辑
  - 增加 ADC 子系统实例
  - 统一对外暴露 SPI、IRQ、ADC 输入、数据回传接口

### ADC 子系统

- `adc_clk_gen.v`
  - 生成 AD9226 采样时钟
  - 初始支持 1 MHz
  - 后续支持可编程分频或 PLL 配置

- `adc_sampler.v`
  - 在 ADC 时钟域采样 `AD_1_DATA[11:0]` / `AD_2_DATA[11:0]`
  - 处理必要的输入寄存与时序对齐

- `adc_channel_ctrl.v`
  - 控制 CH1 / CH2 使能
  - 控制采样顺序
  - 保留单路模式和双路模式

- `adc_frame_ctrl.v`
  - 1024 点计数
  - 生成 `frame_start` / `frame_ready`
  - 管理 CH1 / CH2 的帧边界

- `adc_buffer.v`
  - 片上 RAM 或 FIFO 缓冲
  - 保存双路采样结果
  - 支持 MCU 逐帧读取

- `adc_readout.v`
  - 将缓存数据整理成 MCU 可读格式
  - 支持 CH1 先读、CH2 后读

- `adc_irq.v`
  - 生成中断请求
  - 支持 frame ready / overflow / config error
  - 中断保持直到 MCU 清除

### 预留运算层

- `fft_top.v`
  - FFT 入口封装
  - 第一版仅保留接口

- `dft_top.v`
  - 作为低复杂度备选
  - 可用于小规模点数验证

- `preproc_top.v`
  - 预留去直流、窗函数、抽取等处理

## 5. 推荐目录结构

```text
fpga-dac-awg/
  wavegen.qpf
  wavegen.qsf

  rtl/
    wavegen_top.v

    spi/
      spi_slave.v
      reg_file.v

    adc/
      adc_clk_gen.v
      adc_sampler.v
      adc_channel_ctrl.v
      adc_frame_ctrl.v
      adc_buffer.v
      adc_readout.v
      adc_irq.v

    fft/
      fft_top.v
      dft_top.v
      preproc_top.v

    common/
      reset_sync.v
      sync_edge.v
      pulse_stretch.v

  simulation/
    tb_adc_top.v
    tb_adc_frame_ctrl.v
    tb_spi_slave.v

  mem/
    fft_twiddle/
    testdata/

  tools/
    gen_mif.py
    calc_fword.py

  DOC/
    architecture.md
    register_map.md
    design_decisions.md
    change_log.md
    adc_extension_architecture.md
    adc_extension_register_map.md
    adc_extension_change_log.md
```

## 6. 关键架构判断

### 1024 点能不能放进 FPGA

可以。按 12 bit 原始数据计算，双路 1024 点的存储量很小，放在 Cyclone IV E 片上 RAM 里没有问题。

### 数据怎么搬

第一版建议不引入传统 DMA，而是采用：

```text
ADC -> FPGA 采样寄存器 -> FPGA RAM/FIFO -> MCU 读取
```

### 中断怎么用

用一根 `IRQ` 线即可，FPGA 拉高后通知 MCU：
- 帧满
- 数据准备好
- 发生错误

状态原因放在寄存器里，由 MCU 再读。

## 7. 第一版实现优先级

1. 双路同步采样
2. 单路可使能
3. 1024 点帧缓存
4. SPI 配置
5. 中断通知
6. CH1 / CH2 顺序回传
7. FFT / DFT 接口预留

## 8. 主要风险

- AD9226 采样时钟与数据对齐风险
- FPGA 缓冲深度不足导致溢出
- SPI 回传原始数据速率可能偏慢
- 单路 / 双路切换时的状态清理问题
- FFT 接口和原始数据接口的优先级冲突
