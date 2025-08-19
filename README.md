# VCodePPA: 面向集成电路物理约束优化的Verilog代码数据集

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Paper](https://img.shields.io/badge/Paper-arXiv-green.svg)](link-to-paper)
[![Dataset](https://img.shields.io/badge/Dataset-HuggingFace-yellow.svg)](link-to-dataset)

## 📝 概述

**VCodePPA** 是首个将Verilog代码结构与功耗、性能、面积（PPA）指标精确关联的大规模数据集，专门用于集成电路设计优化。该数据集解决了硬件描述语言生成领域的关键挑战：如何引入基于PPA指标的设计反馈机制，有效指导模型优化，而不仅仅停留在语法和功能正确性层面。

### 核心特性

- **🔢 大规模**: 17,342条高质量样本，分为三个数据集分区
- **🎯 PPA集成**: Verilog代码与硬件实现指标的精确关联
- **🔄 功能等效**: 同一功能的多种实现方式，具有显著的PPA差异
- **📊 全面指标**: 详细的硬件设计指标，包括资源利用率、关键路径延迟、最大工作频率和功耗
- **🛠️ 完整流程**: 从数据生成到模型训练的端到端解决方案

## 🗃️ 数据集结构

数据集包含三个主要组成部分：

### 数据组织结构
VCodePPA/
├── seed_dataset/           # 3,500条精选种子样本，涵盖20个功能类别
├── augmented_dataset/      # 17,342条使用HVMS算法生成的变体
└── evaluation_benchmark/   # 模型评估的标准化测试用例

### 样本组成
每个数据样本包括：
- **Verilog代码**: 功能等效的实现方式，具有结构变化
- **PPA指标**: 使用Xilinx Vivado提取的全面硬件指标
- **功能描述**: 模块功能的自然语言描述
- **设计元数据**: 模块类型、复杂度指标和变换历史

### 数据结构示例
样本ID: behavioral_adder_variant_2
├── 代码: adder_behavioral.v (流水线实现)
├── 描述: "带进位的流水线4位加法器"
├── PPA指标:
│   ├── LUT数量: 8
│   ├── FF数量: 14
│   ├── 最大频率: 979.43 MHz
│   ├── 关键路径延迟: 0.888 ns
│   └── 功耗: 0.454 W
└── 功能类别: 算术运算 > 加法

## 🚀 核心创新

### 1. HVMS算法
**同源Verilog变化搜索** - 基于蒙特卡洛树搜索的算法，用于生成功能等效但PPA特性差异显著的代码变体。

**特性:**
- 跨架构层、逻辑层和时序层的多维代码变换
- 9种变换算子，涵盖FSM编码、接口重构、算子重写等
- 基于UCT策略的智能搜索空间探索
- 支持并行处理，高效完成大规模数据生成

### 2. 双任务训练架构
联合优化的新颖训练框架：
- **主要任务**: 基于功能需求和PPA约束的Verilog代码生成
- **辅助任务**: PPA预测，建立代码结构与硬件指标的直接映射

**核心组件:**
- PPA导向的对比学习损失
- 基于预测分布的实时PPA评估
- 平衡代码质量与多样性的自适应损失函数

## 📊 性能结果

在VCodePPA上训练的模型表现出显著改进：
- **10-15%** 板上资源占用减少
- **8-12%** 功耗降低
- **5-8%** 关键路径延迟缩短
- **增强的功能覆盖** 适用于复杂模块（FSM、FIFO等）

## 🛠️ 安装与使用

### 环境要求
```bash
pip install torch transformers datasets
# PPA评估工具（可选）
# Xilinx Vivado 2022.2 或更高版本
快速开始
加载数据集
pythonfrom datasets import load_dataset

# 加载完整数据集
dataset = load_dataset("your-username/VCodePPA")

# 加载特定分区
train_data = dataset['train']
validation_data = dataset['validation']
test_data = dataset['test']
使用HVMS进行数据增强
pythonfrom vcodepa.hvms import HVMSGenerator

# 初始化HVMS生成器
hvms = HVMSGenerator(
    search_depth=3,
    ppa_threshold=0.2,
    parallel_workers=8
)

# 从种子代码生成变体
variants = hvms.generate_variants(
    seed_code=verilog_code,
    target_count=5,
    transformation_types=['architectural', 'logical', 'timing']
)
使用双任务架构训练
pythonfrom vcodepa.training import DualTaskTrainer

trainer = DualTaskTrainer(
    model_name="deepseek-coder-6.7b",
    dataset=dataset,
    ppa_weight=0.3,
    contrastive_weight=0.2
)

# 训练模型
trainer.train(
    epochs=10,
    batch_size=32,
    learning_rate=2e-5
)
