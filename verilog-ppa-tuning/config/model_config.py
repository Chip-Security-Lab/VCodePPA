"""模型配置文件"""

# 模型参数
MODEL_CONFIG = {
    # 基础模型
    "model_name_or_path": "/public/home/u43077/JYX/DeepSeek-Coder-6.7b",
    "tokenizer_name_or_path": "/public/home/u43077/JYX/DeepSeek-Coder-6.7b",

    # 双任务配置
    "add_ppa_prediction_head": True,
    "ppa_metrics": ["lut", "ff", "io", "cell_count", "max_freq", "reg_to_reg_delay", "end_to_end_delay", "total_power"],
    "ppa_hidden_dim": 512,
    "ppa_embedding_dim": 128,

    # LoRA配置
    "use_lora": True,
    "lora_r": 16,
    "lora_alpha": 32,
    "lora_dropout": 0.05,
    "lora_target_modules": ["q_proj", "v_proj"],

    # 对比学习配置
    "contrastive_temperature": 0.07,
    "contrastive_margin": 0.2,
    "code_embedding_dim": 768,

    # 训练参数
    "max_length": 4096,
    "padding_side": "right",
    "pad_token_id": 0,
}