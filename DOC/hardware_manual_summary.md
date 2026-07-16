# EP4CE30 VER6.1D 硬件手册整理

来源文件：

```text
D:\individual_program\FPGA\Doc\Modules and Development Boards\EP4CE30VER6.1D硬件用户手册.pdf
```

整理日期：2026-07-16

## 1. 开发板定位

该核心板基于 Altera Cyclone IV FPGA，手册中描述的主要型号为：

```text
EP4CE30F23C8N / EP4CE40F23C8N
FBGA484 封装
Speed Grade 8
```

本项目当前 Quartus 工程使用：

```text
FAMILY = Cyclone IV E
DEVICE = EP4CE30F23C8
```

核心板适合做 FPGA、NIOS II、SOPC、外设接口、扩展模块和原型验证。

## 2. 板载主要资源

| 类别 | 资源 | 说明 |
| --- | --- | --- |
| FPGA | EP4CE30F23C8N | Cyclone IV E，FBGA484 |
| DDR2 | MT47H64M16HR-3IT | 1 Gbit，128M x 16 bit |
| 配置 Flash | M25P64 / M25P128 | 兼容 EPCS64/EPCS128，用于固化 FPGA 配置 |
| QSPI Flash | W25Q128 | 128 Mbit，用户数据存储 |
| EEPROM | 24LC04 | 4 Kbit，I2C 接口 |
| SD/TF | MicroSD 卡座 | 支持 SPI/SD 模式 |
| USB 串口 | CH340 / PL2303 | 取决于板卡版本 |
| USB2.0 | CY7C68013A | 高速 USB 控制器 |
| Ethernet | RTL8211EG | 千兆以太网 PHY |
| RTC | DS1302 | 实时时钟 |
| LCD | LCD1602 + TFT LCD | J4/J5 接口 |
| 按键 | S1-S4 + SYSRESET | 上拉输入 |
| LED | LED0-LED3 | 4 个独立 IO |
| 扩展口 | J6/J7/J11/J4 | 大量独立 IO 引出 |

## 3. 时钟与复位

### 3.1 板载时钟

手册说明板上有两个有源晶振，连接到 FPGA 全局时钟引脚：

| 器件 | 网络名 | 频率 | FPGA 引脚 | 说明 |
| --- | --- | --- | --- | --- |
| Y1 | CLKY1 | 27 MHz | PIN_G22 | 可作用户时钟 |
| Y2 | CLKY2 | 50 MHz | PIN_G1 | 常用系统时钟 |

对本项目建议：

```text
CLK50M -> PIN_G1
```

当前 RTL 中：

```verilog
assign sys_clk = CLK50M;
assign dac_clk = CLK50M;
```

后续应改为：

```text
CLK50M -> PLL -> sys_clk / dac_clk
```

第一版 DDS 频率字文档按 100 MHz 计算，因此后续需要用 PLL 从 50 MHz 生成 100 MHz。

### 3.2 系统复位

| 器件 | 网络名 | FPGA 引脚 | 说明 |
| --- | --- | --- | --- |
| S5 | SYSRESET | PIN_E4 | 系统复位按键，带上拉 |

对本项目建议：

```text
Rst_n -> PIN_E4
```

需要注意复位按键是否为低有效。当前 RTL 假定 `Rst_n` 为低有效复位。

## 4. LED 与按键

### 4.1 LED

| 器件 | 网络名 | FPGA 引脚 |
| --- | --- | --- |
| LED1 | LED0 | PIN_E9 |
| LED2 | LED1 | PIN_G9 |
| LED3 | LED2 | PIN_F8 |
| LED4 | LED3 | PIN_E7 |

建议用途：

1. 显示 FPGA 配置是否运行。
2. 显示 SPI 收包状态。
3. 显示 DDS 通道 enable 状态。
4. 显示错误状态，例如 SPI 帧错误。

### 4.2 按键

| 器件 | 网络名 | FPGA 引脚 |
| --- | --- | --- |
| S1 | S1 | PIN_D2 |
| S2 | S2 | PIN_C1 |
| S3 | S3 | PIN_C2 |
| S4 | S4 | PIN_B1 |
| S5 | SYSRESET | PIN_E4 |

对本项目建议：

```text
Key -> PIN_D2
```

第一版按键只作为调试入口，SPI 是正式控制入口。

## 5. 电源与 IO 电平

手册描述的主要电源：

| 电源 | 用途 |
| --- | --- |
| +5V | 外部输入供电 |
| +3.3V | FPGA IO、以太网、串口、Flash、EEPROM、RTC、USB2.0、SD |
| +1.2V | FPGA Core |
| +1.8V | DDR2、FPGA Bank2/Bank3 |
| +2.5V | FPGA Analog Power |
| VREF/VTT 0.9V | DDR2 参考和端接 |
| VCCIO6 | J11 / Bank6 独立 IO 电压，默认 3.3V |

连接外设时重点：

1. J6/J7/J11 默认作为 3.3V IO 使用。
2. J11 属于 Bank6，可通过硬件电源配置改变 IO 电平。
3. AD9767 扩展模块若使用 J6，通常按 3.3V CMOS/TTL 数字接口连接。
4. 不要把 5V 信号直接接入 FPGA 普通 IO。

## 6. 扩展接口总览

手册说明可用扩展 IO：

```text
J6: 38 个 IO
J7: 38 个 IO
J11: 38 个 IO
J4: 11 个 IO
合计约 125 个独立 IO
```

J6、J7、J11 可连接多种扩展模块。手册特别说明：

1. J6、J11 外接模块可以互换，但需要改管脚定义。
2. J7 和 J6/J11 的供电端口不同，如果要互换模块，需要改电阻配置。
3. J6 与 TFT LCD 接口 J5 有复用关系。

对本项目重点：

```text
AD9767 模块优先使用 J6。
```

如果使用 J6 做 AD9767，就不要同时使用 J5 TFT LCD，因为 J5 与 J6 复用大量信号。

## 7. J6 扩展口映射

J6 是本项目 AD9767 模块最相关的接口。

| J6 引脚 | 网络名 | FPGA 引脚 |
| --- | --- | --- |
| J6-1 | 5V | - |
| J6-2 | CLK3 | PIN_B11 |
| J6-3 | CLK2 | PIN_A11 |
| J6-4 | CLK1 | PIN_B12 |
| J6-5 | GND | - |
| J6-6 | J6P6 | PIN_F11 |
| J6-7 | J6P7 | PIN_E11 |
| J6-8 | J6P8 | PIN_E12 |
| J6-9 | J6P9 | PIN_G13 |
| J6-10 | J6P10 | PIN_F13 |
| J6-11 | J6P11 | PIN_E13 |
| J6-12 | J6P12 | PIN_D13 |
| J6-13 | J6P13 | PIN_C13 |
| J6-14 | J6P14 | PIN_B13 |
| J6-15 | J6P15 | PIN_A13 |
| J6-16 | J6P16 | PIN_G14 |
| J6-17 | J6P17 | PIN_F14 |
| J6-18 | J6P18 | PIN_E14 |
| J6-19 | J6P19 | PIN_B14 |
| J6-20 | J6P20 | PIN_A14 |
| J6-21 | J6P21 | PIN_G15 |
| J6-22 | J6P22 | PIN_F15 |
| J6-23 | J6P23 | PIN_E15 |
| J6-24 | J6P24 | PIN_D15 |
| J6-25 | J6P25 | PIN_C15 |
| J6-26 | J6P26 | PIN_B15 |
| J6-27 | J6P27 | PIN_A15 |
| J6-28 | J6P28 | PIN_D17 |
| J6-29 | J6P29 | PIN_C17 |
| J6-30 | J6P30 | PIN_B17 |
| J6-31 | J6P31 | PIN_A17 |
| J6-32 | J6P32 | PIN_B18 |
| J6-33 | J6P33 | PIN_A18 |
| J6-34 | J6P34 | PIN_D19 |
| J6-35 | J6P35 | PIN_C19 |
| J6-36 | J6P36 | PIN_B19 |
| J6-37 | J6P37 | PIN_A19 |
| J6-38 | J6P38 | PIN_B20 |
| J6-39 | J6P39 | PIN_A20 |
| J6-40 | 5V | - |

## 8. AD9767 模块连接建议

项目已有文件：

```text
DOC/引脚分配.CSV
```

该 CSV 与硬件手册 J6 映射对应，可整理出 AD9767 双通道建议约束：

### 8.1 AD9767 通道 1

| AD9767 信号 | 建议 RTL 端口 | FPGA 引脚 |
| --- | --- | --- |
| P1_DB13 | DACA_DATA[13] | PIN_E11 |
| P1_DB12 | DACA_DATA[12] | PIN_E12 |
| P1_DB11 | DACA_DATA[11] | PIN_G13 |
| P1_DB10 | DACA_DATA[10] | PIN_F13 |
| P1_DB9 | DACA_DATA[9] | PIN_E13 |
| P1_DB8 | DACA_DATA[8] | PIN_D13 |
| P1_DB7 | DACA_DATA[7] | PIN_C13 |
| P1_DB6 | DACA_DATA[6] | PIN_B13 |
| P1_DB5 | DACA_DATA[5] | PIN_A13 |
| P1_DB4 | DACA_DATA[4] | PIN_G14 |
| P1_DB3 | DACA_DATA[3] | PIN_F14 |
| P1_DB2 | DACA_DATA[2] | PIN_E14 |
| P1_DB1 | DACA_DATA[1] | PIN_B14 |
| P1_DB0 | DACA_DATA[0] | PIN_A14 |
| WRT1 | DACA_WRT | PIN_G15 |
| CLK1 | DACA_CLK | PIN_F15 |

### 8.2 AD9767 通道 2

| AD9767 信号 | 建议 RTL 端口 | FPGA 引脚 |
| --- | --- | --- |
| CLK2 | DACB_CLK | PIN_E15 |
| WRT2 | DACB_WRT | PIN_D15 |
| P2_DB13 | DACB_DATA[13] | PIN_C15 |
| P2_DB12 | DACB_DATA[12] | PIN_B15 |
| P2_DB11 | DACB_DATA[11] | PIN_A15 |
| P2_DB10 | DACB_DATA[10] | PIN_D17 |
| P2_DB9 | DACB_DATA[9] | PIN_C17 |
| P2_DB8 | DACB_DATA[8] | PIN_B17 |
| P2_DB7 | DACB_DATA[7] | PIN_A17 |
| P2_DB6 | DACB_DATA[6] | PIN_B18 |
| P2_DB5 | DACB_DATA[5] | PIN_A18 |
| P2_DB4 | DACB_DATA[4] | PIN_D19 |
| P2_DB3 | DACB_DATA[3] | PIN_C19 |
| P2_DB2 | DACB_DATA[2] | PIN_B19 |
| P2_DB1 | DACB_DATA[1] | PIN_A19 |
| P2_DB0 | DACB_DATA[0] | PIN_B20 |

### 8.3 连接注意事项

1. J6-1/J6-40 是 5V，J6-5 是 GND，接模块时注意方向。
2. 不要把 J6 的 5V 误接到 FPGA IO。
3. AD9767 数字数据和时钟应使用 3.3V IO 标准。
4. DAC 时钟和 WRT 信号属于高速输出，后续做 Timing Analysis 时要重点检查。
5. 如果示波器看到两个通道波形完全相同，要检查顶层是否仍然存在 `DACB_DATA = DACA_DATA` 这类绑定。

## 9. J7 扩展口映射

| J7 引脚 | 网络名 | FPGA 引脚 |
| --- | --- | --- |
| J7-1 | GND/NC | - |
| J7-2 | J7P2 | PIN_T12 |
| J7-3 | J7P3 | PIN_V12 |
| J7-4 | J7P4 | PIN_T13 |
| J7-5 | J7P5 | PIN_U13 |
| J7-6 | J7P6 | PIN_V13 |
| J7-7 | J7P7 | PIN_W13 |
| J7-8 | J7P8 | PIN_Y13 |
| J7-9 | J7P9 | PIN_V14 |
| J7-10 | J7P10 | PIN_W14 |
| J7-11 | J7P11 | PIN_T14 |
| J7-12 | J7P12 | PIN_U14 |
| J7-13 | J7P13 | PIN_T15 |
| J7-14 | J7P14 | PIN_U15 |
| J7-15 | J7P15 | PIN_W15 |
| J7-16 | J7P16 | PIN_V15 |
| J7-17 | J7P17 | PIN_U16 |
| J7-18 | J7P18 | PIN_V16 |
| J7-19 | J7P19 | PIN_R16 |
| J7-20 | J7P20 | PIN_T16 |
| J7-21 | J7P21 | PIN_Y17 |
| J7-22 | J7P22 | PIN_W17 |
| J7-23 | J7P23 | PIN_U17 |
| J7-24 | J7P24 | PIN_AB13 |
| J7-25 | J7P25 | PIN_AA13 |
| J7-26 | J7P26 | PIN_AB14 |
| J7-27 | J7P27 | PIN_AA14 |
| J7-28 | J7P28 | PIN_AB15 |
| J7-29 | J7P29 | PIN_AA15 |
| J7-30 | J7P30 | PIN_AB16 |
| J7-31 | J7P31 | PIN_AA16 |
| J7-32 | J7P32 | PIN_AB17 |
| J7-33 | J7P33 | PIN_AA17 |
| J7-34 | J7P34 | PIN_AB18 |
| J7-35 | J7P35 | PIN_AA18 |
| J7-36 | J7P36/GND | PIN_AB19 |
| J7-37 | J7P37 | PIN_AA19 |
| J7-38 | J7P38 | PIN_AB20 |
| J7-39 | J7P39 | PIN_AA20 |
| J7-40 | 5V/GND | - |

## 10. J11 扩展口映射

J11 属于 Bank6，可用于普通 IO 或 LVDS。Bank6 电平可调整，默认 3.3V。

| J11 引脚 | 网络名 | FPGA 引脚 |
| --- | --- | --- |
| J11-1 | 5V | - |
| J11-2 | J3P46 | PIN_B21 |
| J11-3 | J3P45 | PIN_B22 |
| J11-4 | J3P44 | PIN_C20 |
| J11-5 | GND | - |
| J11-6 | J3P42 | PIN_C22 |
| J11-7 | J3P41 | PIN_D20 |
| J11-8 | J3P40 | PIN_D21 |
| J11-9 | J3P39 | PIN_D22 |
| J11-10 | J3P38 | PIN_E21 |
| J11-11 | J3P37 | PIN_E22 |
| J11-12 | J3P36 | PIN_F17 |
| J11-13 | J3P35 | PIN_F19 |
| J11-14 | J3P34 | PIN_F20 |
| J11-15 | J3P33 | PIN_F21 |
| J11-16 | J3P32 | PIN_F22 |
| J11-17 | J3P31 | PIN_G17 |
| J11-18 | J3P30 | PIN_G18 |
| J11-19 | J3P29 | PIN_H17 |
| J11-20 | J3P28 | PIN_H18 |
| J11-21 | J3P27 | PIN_H19 |
| J11-22 | J3P26 | PIN_H20 |
| J11-23 | J3P25 | PIN_H21 |
| J11-24 | J3P24 | PIN_H22 |
| J11-25 | J3P23 | PIN_J17 |
| J11-26 | J3P22 | PIN_J18 |
| J11-27 | J3P21 | PIN_J21 |
| J11-28 | J3P20 | PIN_J22 |
| J11-29 | J3P19 | PIN_K17 |
| J11-30 | J3P18 | PIN_K18 |
| J11-31 | J3P17 | PIN_K19 |
| J11-32 | J3P16 | PIN_K21 |
| J11-33 | J3P15 | PIN_K22 |
| J11-34 | J3P14 | PIN_L21 |
| J11-35 | J3P13 | PIN_L22 |
| J11-36 | J3P12 | PIN_M19 |
| J11-37 | J3P11 | PIN_M20 |
| J11-38 | J3P10 | PIN_M21 |
| J11-39 | J3P9 | PIN_M22 |
| J11-40 | 5V | - |

## 11. 常用板载外设引脚速查

### 11.1 LCD1602 J4

| 信号 | FPGA 引脚 |
| --- | --- |
| LCD_D0 | PIN_E1 |
| LCD_D1 | PIN_F2 |
| LCD_D2 | PIN_F1 |
| LCD_D3 | PIN_H2 |
| LCD_D4 | PIN_H1 |
| LCD_D5 | PIN_J3 |
| LCD_D6 | PIN_J2 |
| LCD_D7 | PIN_J1 |
| LCD_E | PIN_G4 |
| LCD_RW | PIN_G5 |
| LCD_RS | PIN_E3 |

### 11.2 QSPI Flash W25Q128

| 信号 | FPGA 引脚 |
| --- | --- |
| QSPI_CLK | PIN_C4 |
| QSPI_CS | PIN_G7 |
| QSPI_IO0 | PIN_F7 |
| QSPI_IO1 | PIN_H10 |
| QSPI_IO2 | PIN_G10 |
| QSPI_IO3 | PIN_G8 |

### 11.3 EEPROM 24LC04

| 信号 | FPGA 引脚 |
| --- | --- |
| E2PROM_SCL | PIN_B2 |
| E2PROM_SDA | PIN_G3 |

### 11.4 RTC DS1302

| 信号 | FPGA 引脚 |
| --- | --- |
| RTC_SCLK | PIN_H6 |
| RTC_RST | PIN_K7 |
| RTC_DATA | PIN_J6 |

### 11.5 SD/TF 卡

| 信号 | FPGA 引脚 |
| --- | --- |
| TF_DATA0 | PIN_H14 |
| TF_DATA1 | PIN_H15 |
| TF_DATA2 | PIN_A16 |
| TF_DATA3 | PIN_B16 |
| TF_CMD | PIN_E16 |
| TF_CLK | PIN_F16 |

## 12. 外设连接指导

### 12.1 供电

1. 外部 DC 供电为 5V。
2. 手册提醒极性为内正外负，不要插错。
3. 也可通过 USB2.0 接口供电，但如果不希望 USB 供电，需要按手册处理相关电阻。

### 12.2 JTAG 下载

1. `.sof` 通过 JTAG 下载到 FPGA，掉电丢失。
2. `.jic` 固化到配置 Flash，掉电后可重新加载运行。
3. 调试阶段优先使用 `.sof`。
4. 最终演示或独立运行时再考虑 `.jic` 固化。

### 12.3 使用扩展模块

1. J6 对 J6、J7 对 J7，连接到底板或扩展板时不要插反。
2. 不用的外设尽量屏蔽，避免 IO 冲突。
3. J6 与 TFT LCD J5 复用，使用 AD9767 时不要同时使用 J5 TFT。
4. J11 可用作 LVDS 或普通 IO，但要确认 Bank6 电压。

### 12.4 本项目推荐连接路径

第一阶段最小连接：

```text
CLK50M  -> PIN_G1
Rst_n   -> PIN_E4
Key     -> PIN_D2
AD9767  -> J6
SPI     -> 暂定空闲扩展 IO，需根据 MCU 接线再分配
```

SPI 引脚手册没有为外部 MCU 专门固定，需要从 J6/J7/J11 空闲 IO 中选择。由于 J6 将被 AD9767 占用，建议 SPI 从 J7 或 J11 选择。

建议优先从 J7 选择 SPI：

```text
SPI_SCLK
SPI_MOSI
SPI_MISO
SPI_CS_N
```

选择原则：

1. 不与 AD9767 的 J6 引脚冲突。
2. 尽量选同一扩展口，方便接线。
3. 避免占用时钟、复位、配置 Flash 和板载关键外设引脚。
4. MCU 与 FPGA 必须共地。
5. MCU IO 电平应为 3.3V；若 MCU 是 5V IO，需要电平转换。

## 13. 对当前 FPGA 项目的直接影响

建议后续在 `wavegen.qsf` 中加入：

```text
CLK50M    -> PIN_G1
Rst_n     -> PIN_E4
Key       -> PIN_D2
DACA_*    -> J6 通道 1 引脚
DACB_*    -> J6 通道 2 引脚
SPI_*     -> 待用户确认 MCU 接线后分配到 J7/J11
```

建议暂缓配置 SPI 引脚，直到确认 MCU 实际接到哪个扩展口。

## 14. 待确认事项

1. AD9767 模块是否确实插在 J6。
2. MCU 的 SPI 线准备接到 J7 还是 J11。
3. MCU IO 电平是否为 3.3V。
4. 是否需要把 LED0-LED3 加入当前 RTL 作为调试状态输出。
5. 是否立即把 AD9767、CLK50M、Rst_n、Key 引脚写入 `wavegen.qsf`。

