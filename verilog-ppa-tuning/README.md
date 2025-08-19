# Verilog-PPA: 具有PPA感知能力的Verilog代码生成模型

这个项目实现了一个用于微调大型语言模型(DeepSeek-Coder-6.7b)的框架，目标是训练一个能够生成具有优良PPA(功耗-性能-面积)特性的Verilog硬件描述语言代码的模型。

## 项目特点

- **双任务架构**：
  - 主任务：Verilog代码生成
  - 辅助任务：PPA指标预测

- **对比学习**：使用代码嵌入和PPA指标嵌入之间的对比学习，帮助模型学习代码与PPA之间的潜在关系

- **高效微调**：
  - 使用LoRA参数高效微调技术
  - 降低显存需求和训练成本

- **数据处理**：
  - 支持处理HVMS生成的大规模Verilog-PPA数据集
  - 实现PPA指标的归一化处理

- **推理和评估**：
  - 支持生成优化的Verilog代码
  - 能够预测代码的PPA性能指标

## 安装

1. 克隆仓库
```bash
git clone https://github.com/yourusername/verilog-ppa-tuning.git
cd verilog-ppa-tuning