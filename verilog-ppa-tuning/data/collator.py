"""数据批处理实现"""
import torch
from dataclasses import dataclass
from typing import Dict, List, Optional, Union, Any
from transformers.tokenization_utils_base import PreTrainedTokenizerBase


@dataclass
class VerilogPPACollator:
    """Verilog-PPA数据集的批处理器"""

    tokenizer: PreTrainedTokenizerBase
    padding: bool = True
    pad_to_multiple_of: Optional[int] = None

    def __call__(self, features):
        batch = {}

        # 处理输入ID和注意力掩码
        batch["input_ids"] = torch.stack([f["input_ids"] for f in features])
        batch["attention_mask"] = torch.stack([f["attention_mask"] for f in features])
        batch["labels"] = torch.stack([f["labels"] for f in features])

        # 如果有PPA值，将它们添加到批次中
        if "ppa_values" in features[0]:
            batch["ppa_values"] = torch.stack([f["ppa_values"] for f in features])

        # 保存原始代码和PPA指标用于评估
        if "original_code" in features[0]:
            batch["original_code"] = [f["original_code"] for f in features]
            batch["raw_ppa"] = [f.get("raw_ppa", {}) for f in features]

        # 保存文件名信息
        if "file_name" in features[0]:
            batch["file_name"] = [f.get("file_name", "unknown_file") for f in features]

        # 保存分组信息和PPA评分
        if "group_id" in features[0]:
            batch["group_id"] = [f.get("group_id", None) for f in features]
            batch["ppa_score"] = torch.tensor([f.get("ppa_score", 0.0) for f in features], dtype=torch.float)
            batch["ppa_improvement"] = torch.tensor([f.get("ppa_improvement", 0.0) for f in features],
                                                    dtype=torch.float)
            batch["design_type"] = [f.get("design_type", "unknown") for f in features]
            batch["is_seed"] = [f.get("is_seed", False) for f in features]

        return batch


@dataclass
class DynamicVerilogPPACollator:
    """动态填充的Verilog-PPA数据集批处理器"""

    tokenizer: PreTrainedTokenizerBase
    padding: bool = True
    max_length: Optional[int] = None
    pad_to_multiple_of: Optional[int] = None
    return_tensors: str = "pt"

    def __call__(self, features: List[Dict[str, Any]]) -> Dict[str, torch.Tensor]:
        """
        使用动态填充将特征列表转换为批次

        Args:
            features: 特征列表

        Returns:
            Dict[str, torch.Tensor]: 批次数据
        """
        # 提取输入文本和PPA值
        input_texts = []
        ppa_values = []
        original_codes = []
        raw_ppas = []

        for f in features:
            if "text" in f:
                input_texts.append(f["text"])
            if "ppa_values" in f:
                ppa_values.append(f["ppa_values"])
            if "original_code" in f:
                original_codes.append(f["original_code"])
            if "raw_ppa" in f:
                raw_ppas.append(f.get("raw_ppa", {}))

        # 动态批量编码输入文本
        if input_texts:
            tokenized_inputs = self.tokenizer(
                input_texts,
                padding=self.padding,
                max_length=self.max_length,
                truncation=True if self.max_length else False,
                pad_to_multiple_of=self.pad_to_multiple_of,
                return_tensors=self.return_tensors
            )

            batch = dict(tokenized_inputs)

            # 设置语言模型标签
            if self.tokenizer.padding_side == "right":
                # 右侧填充时，设置为输入ID的克隆
                batch["labels"] = batch["input_ids"].clone()
            else:
                # 左侧填充时，找到实际内容的起始位置
                labels = batch["input_ids"].clone()
                for i, attention_mask in enumerate(batch["attention_mask"]):
                    padding_idx = torch.nonzero(attention_mask).min().item()
                    labels[i, :padding_idx] = -100  # 忽略左侧填充
                batch["labels"] = labels

        else:
            # 如果没有输入文本，使用已经编码的输入ID和注意力掩码
            batch = {
                "input_ids": torch.stack([f["input_ids"] for f in features]),
                "attention_mask": torch.stack([f["attention_mask"] for f in features]),
                "labels": torch.stack([f["labels"] for f in features])
            }

        # 添加PPA值
        if ppa_values:
            batch["ppa_values"] = torch.stack([torch.tensor(pv, dtype=torch.float) for pv in ppa_values])

        # 添加原始代码和PPA
        if original_codes:
            batch["original_code"] = original_codes

        if raw_ppas:
            batch["raw_ppa"] = raw_ppas

        return batch