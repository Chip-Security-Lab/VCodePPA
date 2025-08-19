"""训练配置文件"""

# 训练参数
TRAIN_CONFIG = {
    # 数据配置
    "train_data_path": "/public/home/u43077/JYX/Json-set/verilog_ppa_train.json",
    "num_proc": 4,

    # 训练超参数
    "per_device_train_batch_size": 4,
    "per_device_eval_batch_size": 4,
    "gradient_accumulation_steps": 4,
    "num_train_epochs": 3,
    "learning_rate": 5e-5,
    "weight_decay": 0.01,
    "warmup_ratio": 0.1,
    "fp16": True,

    # 任务权重
    "code_generation_weight": 1.0,
    "ppa_prediction_weight": 0.5,
    "contrastive_weight": 0.3,
    "ppa_sensitivity": 0.5,

    # 保存设置
    "output_dir": "/public/home/u43077/JYX/output",
    "save_strategy": "steps",
    "save_steps": 50,
    "evaluation_strategy": "no",
    "logging_steps": 50,
    "save_total_limit": 3,

    # 随机种子
    "seed": 42,
}