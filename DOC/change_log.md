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

