# AD9226 扩展变更记录

## 2026-07-16

### AD9226 采集扩展需求与架构草案

分支：
```text
feature/rtl-dds-core
```

变更文件：
```text
DOC/adc_extension_architecture.md
DOC/adc_extension_register_map.md
DOC/adc_extension_change_log.md
```

变更原因：
```text
根据用户确认的双路 AD9226 采集需求，补充产品边界、模块划分、项目目录建议、SPI 寄存器映射、中断语义和数据回传格式。
```

影响范围：
```text
仅文档新增与记录更新，不修改 RTL、Quartus 工程或引脚约束。
```

验证方式：
```text
人工核对现有项目目录结构、现有 SPI 40-bit 帧格式和仓库协作规范。
```

未解决问题：

```text
1. AD9226 采样时钟的最终生成方式需结合板级时钟与时序余量确认。
2. 原始双路数据的 SPI 回传吞吐量需在后续实现阶段评估。
3. FFT / DFT 具体算法接口已预留，但尚未绑定真实实现。
```
