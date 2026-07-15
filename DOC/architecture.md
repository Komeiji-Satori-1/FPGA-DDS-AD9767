# 双通道 AD9767 DDS 任意波形发生器架构草案

## 1. 项目定位

本项目定位为：

```text
双通道 AD9767 DDS 任意波形发生器 FPGA 核心
```

FPGA 负责生成双通道数字波形数据，并通过 AD9767 并行接口输出到 DAC。MCU 通过 SPI 作为主机配置 FPGA；按键作为本地调试或基础控制入口。

## 2. 目标功能

第一版目标：

1. 双通道独立输出。
2. 每通道支持正弦波、方波、三角波。
3. 每通道支持独立频率控制字。
4. 每通道支持独立初相位。
5. 每通道支持输出使能。
6. 支持 MCU 通过 SPI 写入和读取配置寄存器。
7. 支持按键本地调频，主要用于脱离 MCU 时调试。
8. 支持离线生成 ROM `.mif` 波表文件。

第二版可扩展功能：

1. 幅度控制。
2. DC 偏置控制。
3. 任意波形 RAM 在线写入。
4. 扫频。
5. 多通道同步更新。
6. 触发输出或外部同步输入。

## 3. 总体数据流

```text
按键 / MCU SPI
    -> 配置寄存器
    -> DDS 通道 A / DDS 通道 B
    -> 波形选择
    -> 14-bit DAC 数据
    -> AD9767 双通道并行接口
```

## 4. 推荐模块关系

```text
wavegen_top
  ├─ pll
  ├─ reset_sync
  ├─ spi_slave
  ├─ reg_file
  ├─ key_ctrl
  ├─ dds_channel_a
  │   ├─ wave_sine_lut
  │   ├─ wave_square
  │   └─ wave_triangle
  ├─ dds_channel_b
  │   ├─ wave_sine_lut
  │   ├─ wave_square
  │   └─ wave_triangle
  └─ dac_ad9767_if
```

## 5. 模块职责

### wavegen_top

系统顶层。负责连接时钟、复位、SPI、按键、配置寄存器、DDS 通道和 AD9767 输出接口。

### pll

由 Quartus IP 生成。输入 `CLK50M`，输出系统控制时钟和 DDS/DAC 时钟。旧工程中的 PLL 由 Quartus 13 生成，当前项目使用 Quartus 25.1，建议重新生成。

### reset_sync

复位同步模块。把外部复位同步到内部时钟域，降低异步复位释放造成的时序风险。

### spi_slave

SPI 从机底层模块。负责接收 MCU 发来的 SPI 帧，解析读写方向、通道、寄存器地址和写入数据，并返回读数据。

### reg_file

配置寄存器组。保存全局配置和两个通道的配置，向 DDS 通道输出 `enable`、`wave_sel`、`fword`、`phase_init` 等控制信号。

### key_ctrl

本地按键控制模块。第一版建议只用于调试，例如切换预设频率或切换当前调试通道。正式配置以 SPI 为主。

### dds_channel

单通道 DDS 核心。包含相位累加、初相位叠加、波形选择和 14-bit 波形数据输出。

核心公式：

```text
phase_acc <= phase_acc + fword
phase_now = phase_acc + phase_init
```

输出频率：

```text
Fout = Fword * Fclk / 2^32
Fword = Fout * 2^32 / Fclk
```

### wave_sine_lut

正弦波查表模块。使用相位高位作为 ROM 地址，读取 14-bit 正弦波表。

### wave_square

方波逻辑生成模块。建议使用相位最高位决定高低电平，不占 ROM。

### wave_triangle

三角波逻辑生成模块。建议使用相位高位生成上升和下降斜坡，不占 ROM。

### dac_ad9767_if

AD9767 输出接口。负责输出双通道 DAC 数据、DAC 时钟和写入信号。旧工程中把 `DACA_CLK`、`DACA_WRT`、`DACB_CLK`、`DACB_WRT` 直接绑定到 DAC 时钟，第一版可以复用这个思路，但建议封装到独立模块中。

## 6. 推荐目录结构

```text
fpga-dac-awg/
  wavegen.qpf
  wavegen.qsf

  rtl/
    wavegen_top.v
    dds_channel.v
    wave_sine_lut.v
    wave_square.v
    wave_triangle.v
    dac_ad9767_if.v
    spi_slave.v
    reg_file.v
    key_ctrl.v
    reset_sync.v

  ip/
    pll/

  mem/
    sine14_16384.mif

  tools/
    gen_mif.py
    calc_fword.py

  sim/
    tb_dds_channel.v
    tb_spi_slave.v
    tb_wavegen_top.v

  DOC/
    architecture.md
    register_map.md
    design_decisions.md
    change_log.md
    CODEX_COLLABORATION_GUIDELINES.md
    引脚分配.CSV
```

## 7. 参考工程复用分析

参考工程路径：

```text
D:\individual_program\FPGA\Doc\Modules and Development Boards\DDS\AD9767DDS模块\实验例程\ALTERA\EP4CE30_V6.0_DAC9767_ADC9226\EP4CE30_V6.0_DAC9767_ADC9226\Project
```

可复用内容：

1. `Src/sin14bit_16384.mif`：可作为第一版正弦表。
2. `Src/key_filter.v`：可作为按键消抖模块。
3. `Src/Fword_Set.v`：可复用频率字档位设计思路。
4. `Src/DDS_Module.v`：可复用相位累加和 ROM 查表思路。
5. `DAC9767_ADC9226.qsf`：可参考 AD9767 相关引脚约束。

不建议直接复用内容：

1. `Src/pll.v`：旧 Quartus 13 IP，建议重新生成。
2. `Src/ddsrom.v`：旧 Quartus 13 ROM IP wrapper，建议重新生成或改为可推断 ROM。
3. `Src/DAC9767_ADC9226.v`：旧顶层把两个 DAC 通道绑定为同一波形，不符合双通道独立输出需求。
4. `Src/AD9226.v`：本项目第一版重点是 DAC 输出，ADC 暂不纳入核心路径。

## 8. 板级约束来源

当前项目已有：

```text
DOC/引脚分配.CSV
```

该文件包含 AD9767 双通道数据、`WRT`、`CLK` 到 FPGA 引脚的映射。当前读取时中文表头存在编码显示问题，但引脚内容可作为约束来源。正式写入 `wavegen.qsf` 前需要人工核对。

## 9. 主要风险

1. SPI 时钟域与 FPGA 系统时钟域之间存在跨时钟域问题。
2. AD9767 输出时序需要结合实际板卡和芯片手册核对。
3. PLL 和 ROM IP 不建议直接沿用旧 Quartus 13 生成文件。
4. 正弦 ROM 输出可能有一拍延迟，DDS 通道内需要保持波形选择和数据对齐。
5. 按键控制和 SPI 控制同时存在时，需要定义优先级。

## 10. 第一版验收建议

1. 仿真验证 DDS 通道频率字和相位累加行为。
2. 仿真验证 SPI 写寄存器、读寄存器。
3. 仿真验证三种波形选择。
4. Quartus Analysis & Synthesis 通过。
5. 板级测试双通道独立输出：
   - CH A 输出 10 kHz 三角波。
   - CH B 输出 50 kHz 正弦波。

