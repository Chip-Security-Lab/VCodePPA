#!/bin/bash

# 设置环境变量
export PYTHONPATH=/public/home/u43077/JYX/Fine-tuning/verilog-ppa-tuning:$PYTHONPATH
export BNB_CUDA_VERSION=118

# 切换到项目目录
cd /public/home/u43077/JYX/Fine-tuning/verilog-ppa-tuning

# 创建硬编码的检查点目录
mkdir -p /public/home/u43077/JYX/checkpoints

# 创建分布式训练配置文件
cat > config/4gpu_hardcoded_checkpoints.yaml << EOF
# 4-GPU分布式训练配置
per_device_train_batch_size: 1
per_device_eval_batch_size: 1
gradient_accumulation_steps: 4
max_length: 4096
num_train_epochs: 3
lora_r: 16
lora_alpha: 32
lora_dropout: 0.05
gradient_checkpointing: true
fp16: false
logging_steps: 5
save_steps: 50  # 增加到50步保存一次
save_total_limit: 3  # 减少保存的检查点数量
save_lora_only: true  # 只保存LoRA权重
evaluation_strategy: "no"

# PPA 相关参数
ppa_sensitivity: 0.5  # PPA因子敏感度
ppa_warmup_steps: 1000  # PPA因子预热步数，前500步PPA因子影响逐渐增加
weighted_ppa_loss: true             # 是否使用加权PPA损失
EOF

# 使用4个GPU从头开始训练
torchrun --nproc_per_node=4 scripts/train.py \
    --model_name_or_path /public/home/u43077/JYX/DeepSeek-Coder-6.7b \
    --train_data /public/home/u43077/JYX/Json-set/verilog_ppa_train.json \
    --output_dir /public/home/u43077/JYX/output \
    --config config/4gpu_hardcoded_checkpoints.yaml \
    --resume_from_checkpoint checkpoint-5