"""通用工具函数"""
import os
import json
import torch
import random
import numpy as np
import re
from typing import Dict, List, Tuple, Any, Optional, Union, Set


def set_seed(seed: int):
    """
    设置随机种子，确保结果可复现

    Args:
        seed: 随机种子
    """
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def get_device(use_gpu: bool = True, gpu_id: int = 0) -> torch.device:
    """
    获取训练设备

    Args:
        use_gpu: 是否使用GPU
        gpu_id: GPU设备ID

    Returns:
        torch.device: 训练设备
    """
    if use_gpu and torch.cuda.is_available():
        return torch.device(f"cuda:{gpu_id}")
    return torch.device("cpu")


def save_json(data: Any, file_path: str):
    """
    保存JSON数据

    Args:
        data: 要保存的数据
        file_path: 文件路径
    """
    # 确保目录存在
    os.makedirs(os.path.dirname(file_path), exist_ok=True)

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def load_json(file_path: str) -> Any:
    """
    加载JSON数据

    Args:
        file_path: 文件路径

    Returns:
        Any: 加载的数据
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def extract_verilog_module(code: str) -> str:
    """
    从文本中提取Verilog模块代码

    Args:
        code: 包含Verilog代码的文本

    Returns:
        str: 提取的Verilog模块代码
    """
    # 尝试从Markdown代码块中提取
    code_match = re.search(r'```(?:verilog|systemverilog)?\s*([\s\S]*?)```', code)
    if code_match:
        return code_match.group(1).strip()

    # 尝试直接提取模块定义
    module_match = re.search(r'module\s+[\s\S]*?endmodule', code)
    if module_match:
        return module_match.group(0).strip()

    # 返回原始代码
    return code


def format_ppa_metrics(ppa_metrics: Dict[str, float], precision: int = 3) -> str:
    """
    格式化PPA指标为易读的字符串

    Args:
        ppa_metrics: PPA指标字典
        precision: 浮点数精度

    Returns:
        str: 格式化的PPA指标字符串
    """
    formatted = []

    categories = {
        "面积指标": ["lut", "ff", "io", "cell_count"],
        "性能指标": ["max_freq", "reg_to_reg_delay", "end_to_end_delay"],
        "功耗指标": ["total_power"]
    }

    metric_names = {
        "lut": "LUT数量",
        "ff": "触发器数量",
        "io": "IO数量",
        "cell_count": "单元总数",
        "max_freq": "最大频率(MHz)",
        "reg_to_reg_delay": "寄存器间延迟(ns)",
        "end_to_end_delay": "端到端延迟(ns)",
        "total_power": "总功耗(W)"
    }

    for category, metrics in categories.items():
        category_metrics = [
            f"{metric_names.get(metric, metric)}: {ppa_metrics.get(metric, 'N/A') if isinstance(ppa_metrics.get(metric), str) else round(ppa_metrics.get(metric, 0), precision)}"
            for metric in metrics if metric in ppa_metrics
        ]

        if category_metrics:
            formatted.append(f"{category}:")
            formatted.extend([f"  - {m}" for m in category_metrics])

    return "\n".join(formatted)


def compare_ppa_metrics(base_ppa: Dict[str, float], current_ppa: Dict[str, float], precision: int = 3) -> str:
    """
    比较两组PPA指标并生成变化报告

    Args:
        base_ppa: 基准PPA指标
        current_ppa: 当前PPA指标
        precision: 浮点数精度

    Returns:
        str: 格式化的PPA变化报告
    """
    formatted = []

    categories = {
        "面积指标": ["lut", "ff", "io", "cell_count"],
        "性能指标": ["max_freq", "reg_to_reg_delay", "end_to_end_delay"],
        "功耗指标": ["total_power"]
    }

    metric_names = {
        "lut": "LUT数量",
        "ff": "触发器数量",
        "io": "IO数量",
        "cell_count": "单元总数",
        "max_freq": "最大频率(MHz)",
        "reg_to_reg_delay": "寄存器间延迟(ns)",
        "end_to_end_delay": "端到端延迟(ns)",
        "total_power": "总功耗(W)"
    }

    # 优化/退化指标，最大频率越高越好，其他指标越低越好
    better_higher = {"max_freq"}

    for category, metrics in categories.items():
        category_metrics = []

        for metric in metrics:
            if metric in base_ppa and metric in current_ppa:
                base_val = base_ppa[metric]
                current_val = current_ppa[metric]

                # 计算变化百分比
                if base_val != 0:
                    change_pct = (current_val - base_val) / abs(base_val) * 100

                    # 确定是优化还是退化
                    if (metric in better_higher and change_pct > 0) or (metric not in better_higher and change_pct < 0):
                        change_type = "优化"
                    else:
                        change_type = "退化"

                    metric_str = f"{metric_names.get(metric, metric)}: {round(current_val, precision)} (基准: {round(base_val, precision)}, {change_type} {abs(round(change_pct, 2))}%)"
                else:
                    metric_str = f"{metric_names.get(metric, metric)}: {round(current_val, precision)} (基准: {round(base_val, precision)}, 无法计算变化率)"

                category_metrics.append(metric_str)

        if category_metrics:
            formatted.append(f"{category}:")
            formatted.extend([f"  - {m}" for m in category_metrics])

    return "\n".join(formatted)
