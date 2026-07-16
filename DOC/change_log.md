# 变更记录

## 2026-07-15

### 文档初始化

分支：

```text
main
```

修改文件：

```text
DOC/architecture.md
DOC/register_map.md
DOC/design_decisions.md
DOC/change_log.md
```

修改原因：

```text
根据前期讨论，先整理双通道 AD9767 DDS 任意波形发生器的任务、架构、SPI 寄存器和设计决策。
```

影响范围：

```text
仅新增项目文档，不修改 RTL、Quartus 工程文件或脚本。
```

验证方式：

```text
人工检查 Markdown 内容结构和路径引用。
```

未解决问题：

```text
1. SPI 读数据同帧返回还是下一帧返回待确认。
2. 按键控制与 SPI 控制的优先级待确认。
3. PLL 输出 DDS/DAC 时钟频率待确认。
4. AD9767 输出时序和引脚约束需要结合板卡资料最终核对。
```

## 2026-07-15

### 第一批 RTL 骨架

分支：

```text
feature/rtl-dds-core
```

修改文件：

```text
rtl/wavegen_top.v
rtl/reset_sync.v
rtl/spi_slave.v
rtl/reg_file.v
rtl/key_ctrl.v
rtl/dds_channel.v
rtl/wave_sine_lut.v
rtl/wave_square.v
rtl/wave_triangle.v
rtl/dac_ad9767_if.v
tools/gen_mif.py
mem/sine14_16384.mif
mem/sine14_16384.hex
wavegen.qsf
DOC/register_map.md
DOC/design_decisions.md
DOC/change_log.md
```

修改原因：

```text
建立双通道 DDS、SPI 寄存器、基础波形生成和 AD9767 输出接口的第一版 RTL 骨架。
```

影响范围：

```text
新增 RTL 源码、波表生成脚本、正弦 ROM 初始化文件，并将 RTL 文件加入 Quartus 工程。
```

验证方式：

```text
已检查 RTL 文件存在性、QSF 源码引用、MIF 文件头和 HEX 行数。Quartus 和 iverilog 命令行工具当前不在 PATH，Analysis & Synthesis 尚未执行。
```

未解决问题：

```text
1. 当前顶层暂时直接使用 CLK50M 作为 sys_clk 和 dac_clk，后续需要集成 100 MHz PLL。
2. AD9767 引脚约束尚未写入 wavegen.qsf，需要结合 DOC/引脚分配.CSV 核对。
3. SPI 跨时钟域第一版采用请求 toggle 同步，后续需要仿真验证边界时序。
4. AMP_SCALE 和 DC_OFFSET 仅预留寄存器，尚未进入波形数据路径。
```

## 2026-07-16

### 硬件手册整理与引脚电平配置检查

分支：

```text
feature/rtl-dds-core
```

修改文件：

```text
DOC/hardware_manual_summary.md
DOC/change_log.md
wavegen.qsf
.gitignore
```

修改原因：

```text
整理 EP4CE30 VER6.1D 硬件手册中的时钟、复位、按键、扩展口和 AD9767 连接信息；检查并保存 AD9767、SPI、CLK50M、Key、Rst_n 的引脚和 3.3-V LVTTL IO 标准配置。
```

影响范围：

```text
新增硬件手册摘要文档；更新 Quartus 引脚和 IO Standard 约束；忽略 Quartus 生成的 simulation/ 目录。
```

验证方式：

```text
已对照 DOC/引脚分配.CSV 检查 DACA_DATA[13:0]、DACB_DATA[13:0]、DACA_CLK、DACB_CLK、DACA_WRT、DACB_WRT 的引脚映射；已确认 SPI_*、CLK50M、Key、Rst_n 具备 3.3-V LVTTL IO 标准配置。
```

未解决问题：

```text
1. SPI 接线位于 J7-3 到 J7-6，需要实物接线时再次确认顺序。
2. Rst_n 和 Key 使用用户自定义按键引脚，不按硬件摘要中的默认建议判断对错。
3. 后续仍需查看 Quartus 编译报告中的 Bank 电压和 IO Assignment Analysis 结果。
```
