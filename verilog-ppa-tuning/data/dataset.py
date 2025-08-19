"""Verilog-PPA数据集"""
import re  # 用于正则表达式提取功能组ID
import json
import torch
import numpy as np
from torch.utils.data import Dataset
from dataclasses import dataclass
from typing import Dict, List, Optional, Union
from utils.ppa_utils import calculate_ppa_score  # 导入PPA评分函数

class VerilogPPADataset(Dataset):
    """Verilog代码与PPA指标数据集"""

    def __init__(
            self,
            data_path: str,
            tokenizer,
            ppa_metrics: List[str],
            max_length: int = 4096,
            code_only: bool = False
    ):
        """
        初始化Verilog-PPA数据集

        Args:
            data_path: 数据文件路径 (JSON格式)
            tokenizer: 分词器
            ppa_metrics: PPA指标列表
            max_length: 最大序列长度
            code_only: 是否只使用代码生成任务
        """
        self.tokenizer = tokenizer
        self.max_length = max_length
        self.ppa_metrics = ppa_metrics
        self.code_only = code_only

        # 加载数据
        with open(data_path, 'r', encoding='utf-8') as f:
            self.data = json.load(f)

        # 调试输出 - 检查前几个样本的文件名
        print(f"数据集加载完成，共{len(self.data)}个样本")
        for i in range(min(5, len(self.data))):
            file_name = self.data[i].get('file', 'missing')
            print(f"样本 {i} 的文件名: {file_name}")

        # 按功能组织数据
        self.group_data()

        # 再次调试输出 - 检查分组结果
        print(f"数据分组完成，共{len(self.groups)}个组")
        for i, (group_id, group_info) in enumerate(list(self.groups.items())[:3]):
            seed_idx = group_info['seed_idx']
            if seed_idx is not None:
                seed_file = self.data[seed_idx].get('file', 'missing')
                print(f"组 {i}: {group_id}, 种子文件: {seed_file}, 变体数量: {len(group_info['variants'])}")

        # 计算PPA评分
        self.calculate_ppa_scores()

        # 统计指标的最小值和最大值用于归一化
        self.ppa_stats = self._compute_ppa_stats()

    def group_data(self):
        """将数据按功能分组，区分种子代码和变体"""
        self.groups = {}

        # 按文件名排序，确保相同组的文件在一起，且种子代码先于变体代码
        items_with_index = [(idx, item) for idx, item in enumerate(self.data)]

        # 根据文件编号排序
        def get_file_number(item):
            file_name = item[1].get('file', '')
            match = re.match(r'(\d+)', file_name)
            if match:
                return int(match.group(1))
            return 9999  # 如果没有编号，放在最后

        # 首先按编号排序
        items_with_index.sort(key=get_file_number)

        # 重新组织数据
        sorted_indices = []
        for idx, item in items_with_index:
            sorted_indices.append(idx)

            # 从文件名中提取功能组
            file_name = item.get('file', '')
            # 修改后的正则表达式，更稳健地提取组ID - 避免捕获文件扩展名
            group_match = re.match(r'(\d+\.\s+[^_\.]+)', file_name)

            if group_match:
                # 提取组ID并确保格式统一
                group_id = group_match.group(1).strip()

                # 检查是否是种子代码或变体
                is_variant = '_variant' in file_name

                if group_id not in self.groups:
                    self.groups[group_id] = {
                        'seed_idx': None,
                        'variants': []
                    }

                if is_variant:
                    self.groups[group_id]['variants'].append(idx)
                else:
                    # 种子代码
                    self.groups[group_id]['seed_idx'] = idx

                # 添加组ID到数据项
                self.data[idx]['group_id'] = group_id
            else:
                # 使用默认值
                self.data[idx]['group_id'] = f"unknown_group_{idx}"

        # 保存排序后的索引，以便后续使用
        self.sorted_indices = sorted_indices

        # 输出前10个组的信息进行调试
        print(f"组信息调试输出:")
        for i, (group_id, group_info) in enumerate(list(self.groups.items())[:10]):
            seed_idx = group_info['seed_idx']
            variants = group_info['variants']
            seed_file = "无种子文件" if seed_idx is None else self.data[seed_idx].get('file', '未知')
            variant_files = []
            for v_idx in variants[:3]:  # 只显示前3个变体
                variant_files.append(self.data[v_idx].get('file', '未知'))

            variant_str = ", ".join(variant_files)
            if len(variants) > 3:
                variant_str += f"... 等{len(variants)}个变体"

            print(f"组 {i}: {group_id}, 种子文件: {seed_file}, 变体: {variant_str}")

        # 验证分组结果
        problematic_groups = []
        for group_id, group_info in self.groups.items():
            if group_info['seed_idx'] is None and len(group_info['variants']) > 0:
                problematic_groups.append(group_id)

        if problematic_groups:
            print(f"警告: 发现{len(problematic_groups)}个没有种子文件的组:")
            for i, group_id in enumerate(problematic_groups[:5]):  # 只显示前5个
                variant_count = len(self.groups[group_id]['variants'])
                print(f"  问题组 {i + 1}: {group_id}, 变体数量: {variant_count}")
            if len(problematic_groups) > 5:
                print(f"  ... 等{len(problematic_groups)}个问题组")

        print(f"数据分组完成，共{len(self.groups)}个组")

    def calculate_ppa_scores(self):
        """计算每个变体相对于种子代码的PPA评分"""
        from utils.ppa_utils import calculate_ppa_score

        for group_id, group_info in self.groups.items():
            seed_idx = group_info['seed_idx']

            if seed_idx is None:
                continue

            # 计算种子代码的PPA分数
            seed_ppa = self.data[seed_idx].get('ppa', {})
            seed_score_details = calculate_ppa_score(seed_ppa)
            self.data[seed_idx]['ppa_score'] = seed_score_details['total_score']
            self.data[seed_idx]['ppa_score_details'] = seed_score_details
            self.data[seed_idx]['design_type'] = seed_score_details['design_type']

            # 计算变体的PPA分数和相对改进
            for variant_idx in group_info['variants']:
                variant_ppa = self.data[variant_idx].get('ppa', {})
                variant_score_details = calculate_ppa_score(variant_ppa, design_type=seed_score_details['design_type'])
                self.data[variant_idx]['ppa_score'] = variant_score_details['total_score']
                self.data[variant_idx]['ppa_score_details'] = variant_score_details
                self.data[variant_idx]['design_type'] = variant_score_details['design_type']

                # 计算相对于种子的改进
                improvement = variant_score_details['total_score'] - seed_score_details['total_score']
                self.data[variant_idx]['ppa_improvement'] = improvement

    def _compute_ppa_stats(self):
        """计算PPA指标的统计信息用于归一化"""
        stats = {}
        for metric in self.ppa_metrics:
            values = []
            for item in self.data:
                if metric in item.get('ppa', {}):
                    val = item['ppa'][metric]
                    if isinstance(val, (int, float)):  # 跳过"N/A"等非数值
                        values.append(val)

            if values:
                stats[metric] = {
                    'min': min(values),
                    'max': max(values),
                    'mean': sum(values) / len(values),
                    'std': np.std(values)
                }
            else:
                stats[metric] = {'min': 0, 'max': 1, 'mean': 0, 'std': 1}
        return stats

    def normalize_ppa(self, ppa):
        """归一化PPA指标"""
        normalized = {}
        for metric in self.ppa_metrics:
            if metric in ppa and metric in self.ppa_stats:
                if isinstance(ppa[metric], (int, float)):  # 跳过"N/A"等非数值
                    # Z-score标准化
                    normalized[metric] = (ppa[metric] - self.ppa_stats[metric]['mean']) / (
                            self.ppa_stats[metric]['std'] + 1e-8)
                else:
                    normalized[metric] = 0.0
            else:
                normalized[metric] = 0.0
        return normalized

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        item = self.data[idx]

        # 提取Verilog代码和对应的PPA指标
        code = item['code']

        # 获取文件名 - 尝试多种可能的字段名
        file_name = "unknown_file"
        for field in ['file', 'filename', 'file_name', 'path']:
            if field in item and item[field]:
                file_name = item[field]
                break

        # 如果还是找不到，为测试生成一个基于索引的文件名
        if file_name == "unknown_file":
            file_name = f"test_file_{idx}.v"

        # 构建输入提示
        prompt = f"请生成一个具有优良PPA指标的Verilog模块:\n\n```verilog\n{code}\n```"

        # 对输入进行编码
        tokenized_input = self.tokenizer(
            prompt,
            max_length=self.max_length,
            padding="max_length",
            truncation=True,
            return_tensors="pt"
        )

        # 准备输入数据
        input_ids = tokenized_input.input_ids.squeeze(0)
        attention_mask = tokenized_input.attention_mask.squeeze(0)

        # 如果只需要代码生成任务
        if self.code_only:
            return {
                "input_ids": input_ids,
                "attention_mask": attention_mask,
                "labels": input_ids.clone(),  # 自回归训练，输出与输入相同
                "file_name": file_name  # 添加文件名
            }

        # 双任务情况：添加PPA指标
        normalized_ppa = self.normalize_ppa(item.get('ppa', {}))
        ppa_values = torch.tensor([normalized_ppa.get(metric, 0.0) for metric in self.ppa_metrics], dtype=torch.float)

        result = {
            "input_ids": input_ids,
            "attention_mask": attention_mask,
            "labels": input_ids.clone(),
            "ppa_values": ppa_values,
            "original_code": code,
            "raw_ppa": item.get('ppa', {}),
            "group_id": item.get('group_id', None),
            "ppa_score": item.get('ppa_score', 0.0),
            "ppa_improvement": item.get('ppa_improvement', 0.0),
            "design_type": item.get('design_type', 'unknown'),
            "is_seed": item.get('file', '').find('_variant') == -1,
            "file_name": file_name,  # 添加文件名
            "file": file_name  # 多添加一个字段以增加健壮性
        }

        return result

@dataclass
class VerilogPPACollator:
    """Verilog-PPA数据集的批处理器"""

    tokenizer: any
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

        # 保存分组信息和PPA评分
        if "group_id" in features[0]:
            batch["group_id"] = [f.get("group_id", None) for f in features]
            batch["ppa_score"] = torch.tensor([f.get("ppa_score", 0.0) for f in features], dtype=torch.float)
            batch["ppa_improvement"] = torch.tensor([f.get("ppa_improvement", 0.0) for f in features],
                                                    dtype=torch.float)
            batch["design_type"] = [f.get("design_type", "unknown") for f in features]
            batch["is_seed"] = [f.get("is_seed", False) for f in features]

        # 确保文件名被传递
        batch["file_name"] = []
        for f in features:
            # 尝试多种可能的文件名字段
            if "file_name" in f:
                batch["file_name"].append(f["file_name"])
            elif "file" in f:
                batch["file_name"].append(f["file"])
            else:
                batch["file_name"].append("unknown_file")

        return batch


class GroupSequentialSampler(torch.utils.data.Sampler):
    """按组顺序抽取数据的采样器"""

    def __init__(self, dataset):
        self.dataset = dataset
        self.indices = []

        # 获取所有组
        groups = list(dataset.groups.keys())

        # 按数字ID排序
        groups.sort(key=self.get_group_number)

        # 按组构建索引序列
        for group_id in groups:
            group_info = dataset.groups[group_id]

            # 添加种子代码（确保种子代码在前）
            if group_info['seed_idx'] is not None:
                self.indices.append(group_info['seed_idx'])

            # 添加变体代码
            if group_info['variants']:
                # 按变体编号排序
                def get_variant_idx(idx):
                    file_name = dataset.data[idx].get('file', '')
                    return self.get_variant_number(file_name)

                sorted_variants = sorted(group_info['variants'], key=get_variant_idx)
                self.indices.extend(sorted_variants)

        # 打印前20个样本的文件名，用于调试
        print("顺序采样器初始化完成，前20个样本:")
        for i, idx in enumerate(self.indices[:20]):
            file_name = dataset.data[idx].get('file', '未知')
            print(f"  样本 {i}: {file_name}")

    def __iter__(self):
        return iter(self.indices)

    def __len__(self):
        return len(self.indices)

    @staticmethod
    def get_group_number(group_id):
        """从组ID中提取数字"""
        # 例如从 "1. Behavioral Adder" 提取数字 1
        match = re.match(r'(\d+)', group_id)
        if match:
            return int(match.group(1))
        return 9999  # 默认高值

    @staticmethod
    def get_variant_number(file_name):
        """从文件名中提取变体编号"""
        # 例如从 "1. Behavioral Adder_variant_1.v" 提取变体编号 1
        match = re.search(r'_variant_(\d+)', file_name)
        if not match:
            match = re.search(r'_variant(\d+)', file_name)  # 尝试不同的格式

        if match:
            return int(match.group(1))
        return 0  # 非变体或无法识别的变体编号
