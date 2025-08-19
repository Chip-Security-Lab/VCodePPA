"""双任务模型架构：代码生成 + PPA预测"""
import torch
import torch.nn as nn
import torch.nn.functional as F
import datetime
import os
import json
from transformers import AutoModelForCausalLM, AutoConfig
from peft import get_peft_model, LoraConfig, TaskType
from model.loss import PPAGuidedContrastiveLoss
from typing import Dict, List, Tuple, Optional, Union, Any


class PPAPredictionHead(nn.Module):
    """PPA预测头"""

    def __init__(self, hidden_size, ppa_hidden_dim, num_ppa_metrics):
        super().__init__()
        self.dense = nn.Linear(hidden_size, ppa_hidden_dim)
        self.activation = nn.GELU()
        self.layer_norm = nn.LayerNorm(ppa_hidden_dim)
        self.out_proj = nn.Linear(ppa_hidden_dim, num_ppa_metrics)

    def forward(self, hidden_states):
        # 使用最后一个隐藏状态
        pooled_output = hidden_states[:, -1]
        x = self.dense(pooled_output)
        x = self.activation(x)
        x = self.layer_norm(x)
        x = self.out_proj(x)
        return x


class VerilogPPAModel(nn.Module):
    """双任务Verilog-PPA模型"""

    def __init__(self, config):
        super().__init__()

    def __init__(self, config):
        super().__init__()

        # 加载基础模型
        model_config = AutoConfig.from_pretrained(config["model_name_or_path"])

        # 启用梯度检查点以减少内存使用
        if config.get("gradient_checkpointing", False):
            model_config.gradient_checkpointing = True
            print("启用梯度检查点以减少内存使用")

        self.base_model = AutoModelForCausalLM.from_pretrained(
            config["model_name_or_path"],
            config=model_config,
            torch_dtype=torch.float16 if config.get("fp16", False) else torch.float32,
        )

        # 确保梯度检查点被正确启用
        if config.get("gradient_checkpointing", False):
            self.base_model.gradient_checkpointing_enable()

        # 应用LoRA参数高效微调
        if config.get("use_lora", False):
            peft_config = LoraConfig(
                task_type=TaskType.CAUSAL_LM,
                inference_mode=False,
                r=config["lora_r"],
                lora_alpha=config["lora_alpha"],
                lora_dropout=config["lora_dropout"],
                target_modules=config["lora_target_modules"],
            )
            self.base_model = get_peft_model(self.base_model, peft_config)
            self.base_model.print_trainable_parameters()

        # 添加PPA预测头
        if config.get("add_ppa_prediction_head", False):
            hidden_size = self.base_model.config.hidden_size
            self.ppa_head = PPAPredictionHead(
                hidden_size=hidden_size,
                ppa_hidden_dim=config["ppa_hidden_dim"],
                num_ppa_metrics=len(config["ppa_metrics"])
            )

        # 对比学习投影头
        if "contrastive_temperature" in config:
            self.code_proj = nn.Linear(hidden_size, config["code_embedding_dim"])
            self.ppa_proj = nn.Linear(len(config["ppa_metrics"]), config["code_embedding_dim"])
            self.contrastive_temperature = config["contrastive_temperature"]

        self.config = config

    def forward(
            self,
            input_ids: Optional[torch.Tensor] = None,
            attention_mask: Optional[torch.Tensor] = None,
            labels: Optional[torch.Tensor] = None,
            ppa_values: Optional[torch.Tensor] = None,
            group_id: Optional[List[str]] = None,
            ppa_score: Optional[torch.Tensor] = None,
            ppa_improvement: Optional[torch.Tensor] = None,
            design_type: Optional[List[str]] = None,
            is_seed: Optional[List[bool]] = None,
            raw_ppa: Optional[List[Dict]] = None,
            **kwargs
    ):
        outputs = self.base_model(
            input_ids=input_ids,
            attention_mask=attention_mask,
            labels=labels,
            output_hidden_states=True,
            return_dict=True,
            **kwargs
        )

        result = {
            "lm_loss": outputs.loss,
            "logits": outputs.logits,
        }

        # 添加设计类型和原始PPA到结果中
        if design_type is not None:
            result["design_type"] = design_type

        if raw_ppa is not None:
            result["raw_ppa"] = raw_ppa

        # 如果没有PPA预测任务，直接返回语言模型损失
        if not hasattr(self, "ppa_head") or ppa_values is None:
            return result

        # PPA预测任务
        hidden_states = outputs.hidden_states[-1]
        ppa_pred = self.ppa_head(hidden_states)
        result["ppa_pred"] = ppa_pred

        # 计算PPA预测损失
        if ppa_values is not None:
            mse_loss = nn.MSELoss()(ppa_pred, ppa_values)
            result["ppa_mse_loss"] = mse_loss

        # 对比学习损失 - 使用新的PPA导向损失
        if hasattr(self, "code_proj") and ppa_values is not None:
            # 获取代码和PPA的嵌入表示
            code_hidden = hidden_states[:, -1]  # 取最后一个隐藏状态
            code_emb = self.code_proj(code_hidden)
            ppa_emb = self.ppa_proj(ppa_values)

            # 使用PPA导向的对比学习损失
            if (group_id is not None and ppa_score is not None and
                    design_type is not None and is_seed is not None):

                contrastive_loss_func = PPAGuidedContrastiveLoss(
                    temperature=self.contrastive_temperature
                )
                contrastive_loss, code_ppa_loss, variant_loss = contrastive_loss_func(
                    code_emb, ppa_emb, group_id, ppa_score, design_type, is_seed
                )

                result["contrastive_loss"] = contrastive_loss
                result["code_ppa_loss"] = code_ppa_loss
                result["variant_loss"] = variant_loss
            else:
                # 回退到基础对比学习
                code_emb = F.normalize(code_emb, dim=1)
                ppa_emb = F.normalize(ppa_emb, dim=1)

                # 计算相似度矩阵
                similarity = torch.matmul(code_emb, ppa_emb.transpose(0, 1)) / self.contrastive_temperature

                # 对比学习损失
                labels = torch.arange(similarity.size(0), device=similarity.device)
                contrastive_loss = nn.CrossEntropyLoss()(similarity, labels)

                result["contrastive_loss"] = contrastive_loss

        return result

    # 在 VerilogPPAModel 类中添加这些方法
    def save_pretrained(self, save_directory):
        """保存模型到指定目录"""

        # 确保目录存在
        os.makedirs(save_directory, exist_ok=True)

        # 1. 保存模型配置
        config_dict = {k: v for k, v in self.config.items() if not k.startswith('_')}
        with open(os.path.join(save_directory, "config.json"), 'w') as f:
            json.dump(config_dict, f, indent=2)

        # 2. 保存基础模型
        self.base_model.save_pretrained(save_directory)

        # 3. 保存PPA预测头（如果存在）
        if hasattr(self, "ppa_head"):
            torch.save(self.ppa_head.state_dict(), os.path.join(save_directory, "ppa_head.bin"))

        # 4. 保存对比学习投影头（如果存在）
        if hasattr(self, "code_proj"):
            torch.save(self.code_proj.state_dict(), os.path.join(save_directory, "code_proj.bin"))
            torch.save(self.ppa_proj.state_dict(), os.path.join(save_directory, "ppa_proj.bin"))

    @classmethod
    def from_pretrained(cls, pretrained_model_path, *args, **kwargs):
        """从预训练模型加载"""
        import os
        import json
        import torch

        # 1. 加载配置
        with open(os.path.join(pretrained_model_path, "config.json"), 'r') as f:
            config = json.load(f)

        # 2. 更新传入的配置
        for k, v in kwargs.items():
            config[k] = v

        # 3. 创建模型实例
        model = cls(config)

        # 4. 加载PPA预测头（如果存在）
        ppa_head_path = os.path.join(pretrained_model_path, "ppa_head.bin")
        if os.path.exists(ppa_head_path) and hasattr(model, "ppa_head"):
            model.ppa_head.load_state_dict(torch.load(ppa_head_path))

        # 5. 加载对比学习投影头（如果存在）
        code_proj_path = os.path.join(pretrained_model_path, "code_proj.bin")
        ppa_proj_path = os.path.join(pretrained_model_path, "ppa_proj.bin")

        if os.path.exists(code_proj_path) and hasattr(model, "code_proj"):
            model.code_proj.load_state_dict(torch.load(code_proj_path))

        if os.path.exists(ppa_proj_path) and hasattr(model, "ppa_proj"):
            model.ppa_proj.load_state_dict(torch.load(ppa_proj_path))

        return model
