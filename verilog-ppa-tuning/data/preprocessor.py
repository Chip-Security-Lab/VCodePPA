"""Verilog-PPA数据预处理工具 - 优化版"""
import os
import json
import logging
import re
from typing import Dict, List, Tuple, Any
import pandas as pd
import numpy as np
from tqdm import tqdm


class VerilogPPAPreprocessor:
    """Verilog代码和PPA指标数据预处理 - 针对特定数据集格式优化"""

    def __init__(self, logger=None):
        """
        初始化预处理器

        Args:
            logger: 日志记录器，如果为None则创建一个新的
        """
        self.logger = logger or logging.getLogger(self.__class__.__name__)

    def process_verilog_ppa_data(
            self,
            verilog_dir: str,
            ppa_dir: str,
            output_file: str,
            split_ratio: Tuple[float, float, float] = (0.8, 0.1, 0.1),
            max_samples: int = None
    ):
        """
        处理Verilog-PPA数据集

        Args:
            verilog_dir: Verilog代码目录 (例如 "E:\\研究生-4.24\\VCodePPA\\1. Verilog_code")
            ppa_dir: PPA报告目录 (例如 "E:\\研究生-4.24\\VCodePPA\\2. PPA_report")
            output_file: 输出文件路径
            split_ratio: 训练、验证、测试集比例
            max_samples: 最大样本数量，None表示处理所有数据
        """
        self.logger.info(f"处理Verilog-PPA数据: {verilog_dir}, {ppa_dir}")

        # 收集Verilog文件
        verilog_files = []
        for root, _, files in os.walk(verilog_dir):
            for file in files:
                if file.endswith(('.v', '.sv')):
                    verilog_files.append(os.path.join(root, file))

        self.logger.info(f"找到 {len(verilog_files)} 个Verilog文件")

        if max_samples and max_samples < len(verilog_files):
            import random
            random.shuffle(verilog_files)
            verilog_files = verilog_files[:max_samples]
            self.logger.info(f"限制处理 {max_samples} 个样本")

        # 处理数据
        dataset = []
        for verilog_file in tqdm(verilog_files, desc="处理数据"):
            # 提取基本文件名
            basename = os.path.basename(verilog_file)
            name_without_ext = os.path.splitext(basename)[0]

            # 尝试多种可能的PPA报告文件命名模式
            ppa_file = None
            possible_ppa_files = [
                os.path.join(ppa_dir, f"{name_without_ext}_report.txt"),  # 基本模式：文件名_report.txt
                os.path.join(ppa_dir, f"{name_without_ext.replace('_variant', '')}_variant{name_without_ext.split('_variant_')[1] if '_variant_' in name_without_ext else ''}_report.txt"),  # 处理含有variant的情况
                os.path.join(ppa_dir, f"{name_without_ext.split('_variant')[0]}_report.txt" if '_variant' in name_without_ext else f"{name_without_ext}_report.txt")  # 尝试不带variant的基本名称
            ]

            # 查找存在的PPA文件
            for possible_file in possible_ppa_files:
                if os.path.exists(possible_file):
                    ppa_file = possible_file
                    break

            # 如果PPA报告不存在，尝试进一步的匹配策略
            if not ppa_file:
                # 如果文件名包含编号前缀(如 "1. Behavioral Adder")，尝试按前缀匹配
                prefix_match = re.match(r'^(\d+\.\s+[^_]+)', name_without_ext)
                if prefix_match:
                    prefix = prefix_match.group(1)
                    # 在PPA目录中查找所有匹配此前缀的文件
                    for ppa_filename in os.listdir(ppa_dir):
                        if ppa_filename.startswith(prefix) and ppa_filename.endswith('_report.txt'):
                            if "_variant" in basename and "_variant" in ppa_filename:
                                variant_match = re.search(r'_variant_(\d+)', basename)
                                ppa_variant_match = re.search(r'_variant_(\d+)', ppa_filename)
                                if variant_match and ppa_variant_match and variant_match.group(1) == ppa_variant_match.group(1):
                                    ppa_file = os.path.join(ppa_dir, ppa_filename)
                                    break
                            elif "_variant" not in basename and "_variant" not in ppa_filename:
                                ppa_file = os.path.join(ppa_dir, ppa_filename)
                                break

            # 如果仍然找不到PPA报告，使用模糊匹配
            if not ppa_file:
                basename_no_ext = name_without_ext.lower()
                closest_match = None
                highest_similarity = 0

                for ppa_filename in os.listdir(ppa_dir):
                    if not ppa_filename.endswith('_report.txt'):
                        continue

                    ppa_basename = os.path.splitext(ppa_filename)[0].replace('_report', '').lower()
                    # 使用简单的字符串相似度计算
                    from difflib import SequenceMatcher
                    similarity = SequenceMatcher(None, basename_no_ext, ppa_basename).ratio()

                    if similarity > highest_similarity and similarity > 0.7:  # 设置阈值
                        highest_similarity = similarity
                        closest_match = ppa_filename

                if closest_match:
                    ppa_file = os.path.join(ppa_dir, closest_match)
                    self.logger.info(f"使用模糊匹配找到PPA报告: {verilog_file} -> {closest_match} (相似度: {highest_similarity:.2f})")

            # 如果PPA报告不存在，跳过这个样本
            if not ppa_file:
                self.logger.warning(f"找不到PPA报告: {verilog_file}")
                continue

            # 读取Verilog代码
            try:
                with open(verilog_file, 'r', encoding='utf-8', errors='ignore') as f:
                    code = f.read()
            except Exception as e:
                self.logger.warning(f"读取Verilog文件失败: {verilog_file}, 错误: {str(e)}")
                continue

            # 解析PPA报告
            try:
                ppa_metrics = self._parse_ppa_report(ppa_file)

                # 检查PPA指标是否有效
                if not ppa_metrics:
                    self.logger.warning(f"无法从PPA报告中提取有效指标: {ppa_file}")
                    continue

                # 添加到数据集
                dataset.append({
                    'code': code,
                    'ppa': ppa_metrics,
                    'file': basename,
                    'ppa_file': os.path.basename(ppa_file)
                })
            except Exception as e:
                self.logger.warning(f"解析PPA报告失败: {ppa_file}, 错误: {str(e)}")
                continue

        self.logger.info(f"成功处理 {len(dataset)} 个样本")

        # 拆分数据集
        splits = self._split_dataset(dataset, split_ratio)

        # 保存数据集
        output_dir = os.path.dirname(output_file)
        os.makedirs(output_dir, exist_ok=True)

        # 计算文件基本名称和扩展名
        base_name, ext = os.path.splitext(output_file)

        # 保存各拆分
        for split_name, split_data in splits.items():
            split_file = f"{base_name}_{split_name}{ext}"
            with open(split_file, 'w', encoding='utf-8') as f:
                json.dump(split_data, f, ensure_ascii=False, indent=2)

            self.logger.info(f"保存 {split_name} 集: {split_file}, 包含 {len(split_data)} 个样本")

        # 保存PPA统计信息
        self._save_ppa_stats(splits['train'], f"{base_name}_ppa_stats.json")

        return splits

    def _parse_ppa_report(self, ppa_file: str) -> Dict[str, float]:
        """
        解析PPA报告文件 - 增强版本，支持多种格式

        Args:
            ppa_file: PPA报告文件路径

        Returns:
            Dict[str, float]: PPA指标字典
        """
        ppa_metrics = {}

        try:
            with open(ppa_file, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            # 提取LUT数量 - 支持多种格式
            lut_patterns = [
                r'LUT Count:\s*(\d+)',
                r'LUTs?:\s*(\d+)',
                r'Number of LUTs?:\s*(\d+)'
            ]
            for pattern in lut_patterns:
                lut_match = re.search(pattern, content)
                if lut_match:
                    ppa_metrics['lut'] = int(lut_match.group(1))
                    break

            # 提取FF数量 - 支持多种格式
            ff_patterns = [
                r'FF Count:\s*(\d+)',
                r'Flip-Flops?:\s*(\d+)',
                r'Number of Flip-Flops?:\s*(\d+)',
                r'FFs?:\s*(\d+)'
            ]
            for pattern in ff_patterns:
                ff_match = re.search(pattern, content)
                if ff_match:
                    ppa_metrics['ff'] = int(ff_match.group(1))
                    break

            # 提取IO数量 - 支持多种格式
            io_patterns = [
                r'IO Count:\s*(\d+)',
                r'IOs?:\s*(\d+)',
                r'Number of IOs?:\s*(\d+)'
            ]
            for pattern in io_patterns:
                io_match = re.search(pattern, content)
                if io_match:
                    ppa_metrics['io'] = int(io_match.group(1))
                    break

            # 提取Cell数量 - 支持多种格式
            cell_patterns = [
                r'Cell Count:\s*(\d+)',
                r'Cells?:\s*(\d+)',
                r'Number of Cells?:\s*(\d+)',
                r'Total Cell Count:\s*(\d+)'
            ]
            for pattern in cell_patterns:
                cell_match = re.search(pattern, content)
                if cell_match:
                    ppa_metrics['cell_count'] = int(cell_match.group(1))
                    break

            # 提取最大频率 - 支持多种格式并处理组合逻辑
            if "Combinational logic" in content or "N/A" in content:
                # 对于组合逻辑，将最大频率设为0或特殊值
                ppa_metrics['max_freq'] = 0.0
            else:
                freq_patterns = [
                    r'Maximum Clock Frequency:\s*([\d\.]+)\s*MHz',
                    r'Max Clock Frequency:\s*([\d\.]+)\s*MHz',
                    r'Maximum Frequency:\s*([\d\.]+)\s*MHz',
                    r'Max Frequency:\s*([\d\.]+)\s*MHz'
                ]
                for pattern in freq_patterns:
                    freq_match = re.search(pattern, content)
                    if freq_match:
                        ppa_metrics['max_freq'] = float(freq_match.group(1))
                        break

            # 提取端到端延迟 - 支持多种格式
            delay_patterns = [
                r'End-to-End Path Delay:\s*([\d\.]+)\s*ns',
                r'Path Delay:\s*([\d\.]+)\s*ns',
                r'Total Path Delay:\s*([\d\.]+)\s*ns'
            ]
            for pattern in delay_patterns:
                delay_match = re.search(pattern, content)
                if delay_match:
                    ppa_metrics['end_to_end_delay'] = float(delay_match.group(1))
                    break

            # 提取寄存器到寄存器延迟 - 支持多种格式
            reg_delay_patterns = [
                r'Reg-to-Reg Critical Path Delay:\s*([\d\.]+)\s*ns',
                r'Register to Register Delay:\s*([\d\.]+)\s*ns',
                r'Critical Path Delay:\s*([\d\.]+)\s*ns'
            ]
            for pattern in reg_delay_patterns:
                reg_delay_match = re.search(pattern, content)
                if reg_delay_match:
                    ppa_metrics['reg_to_reg_delay'] = float(reg_delay_match.group(1))
                    break

            # 提取总功耗 - 支持多种格式
            power_patterns = [
                r'Total Power Consumption:\s*([\d\.]+)\s*W',
                r'Total Power:\s*([\d\.]+)\s*W',
                r'Power Consumption:\s*([\d\.]+)\s*W',
                r'Power:\s*([\d\.]+)\s*W'
            ]
            for pattern in power_patterns:
                power_match = re.search(pattern, content)
                if power_match:
                    ppa_metrics['total_power'] = float(power_match.group(1))
                    break

        except Exception as e:
            self.logger.error(f"解析PPA报告出错: {ppa_file}, {str(e)}")

        return ppa_metrics

    def _split_dataset(
            self,
            dataset: List[Dict[str, Any]],
            split_ratio: Tuple[float, float, float]
    ) -> Dict[str, List[Dict[str, Any]]]:
        """
        拆分数据集为训练、验证和测试集

        Args:
            dataset: 数据集列表
            split_ratio: 训练、验证、测试集比例

        Returns:
            Dict[str, List[Dict[str, Any]]]: 拆分后的数据集
        """
        import random
        random.shuffle(dataset)

        train_ratio, val_ratio, test_ratio = split_ratio
        assert abs(sum(split_ratio) - 1.0) < 1e-10, "拆分比例总和必须为1"

        n = len(dataset)
        train_size = int(n * train_ratio)
        val_size = int(n * val_ratio)

        train_data = dataset[:train_size]
        val_data = dataset[train_size:train_size + val_size]
        test_data = dataset[train_size + val_size:]

        return {
            'train': train_data,
            'val': val_data,
            'test': test_data
        }

    def _save_ppa_stats(self, train_dataset: List[Dict[str, Any]], output_file: str):
        """
        计算并保存PPA指标统计信息

        Args:
            train_dataset: 训练集数据
            output_file: 输出文件路径
        """
        # 收集所有的PPA指标
        ppa_metrics = {}

        for item in train_dataset:
            for metric, value in item['ppa'].items():
                if metric not in ppa_metrics:
                    ppa_metrics[metric] = []
                ppa_metrics[metric].append(value)

        # 计算统计信息
        stats = {}
        for metric, values in ppa_metrics.items():
            if values:
                stats[metric] = {
                    'min': min(values),
                    'max': max(values),
                    'mean': sum(values) / len(values),
                    'std': np.std(values)
                }

        # 保存统计信息
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(stats, f, ensure_ascii=False, indent=2)

        self.logger.info(f"保存PPA统计信息: {output_file}")

    def analyze_dataset_statistics(self, dataset_file: str, output_file: str = None):
        """
        分析数据集统计信息并生成报告

        Args:
            dataset_file: 数据集文件路径
            output_file: 输出报告文件路径
        """
        # 加载数据集
        with open(dataset_file, 'r', encoding='utf-8') as f:
            dataset = json.load(f)

        self.logger.info(f"分析数据集: {dataset_file}, 样本数: {len(dataset)}")

        # 收集PPA指标统计
        ppa_metrics = {}
        code_lengths = []

        for item in dataset:
            # 代码长度统计
            code_lengths.append(len(item['code']))

            # PPA指标统计
            for metric, value in item.get('ppa', {}).items():
                if metric not in ppa_metrics:
                    ppa_metrics[metric] = []
                ppa_metrics[metric].append(value)

        # 计算统计信息
        stats = {
            "dataset_size": len(dataset),
            "code_length": {
                "min": min(code_lengths),
                "max": max(code_lengths),
                "mean": sum(code_lengths) / len(code_lengths),
                "median": sorted(code_lengths)[len(code_lengths) // 2]
            },
            "ppa_metrics": {}
        }

        for metric, values in ppa_metrics.items():
            stats["ppa_metrics"][metric] = {
                "min": min(values),
                "max": max(values),
                "mean": sum(values) / len(values),
                "median": sorted(values)[len(values) // 2],
                "std": np.std(values)
            }

        # 输出统计信息
        self.logger.info(f"数据集统计: {stats['dataset_size']} 样本")
        self.logger.info(f"代码长度: 最小={stats['code_length']['min']}, 最大={stats['code_length']['max']}, 平均={stats['code_length']['mean']:.2f}")

        for metric, metric_stats in stats["ppa_metrics"].items():
            self.logger.info(f"{metric}: 最小={metric_stats['min']:.2f}, 最大={metric_stats['max']:.2f}, 平均={metric_stats['mean']:.2f}, 标准差={metric_stats['std']:.2f}")

        # 保存报告
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(stats, f, ensure_ascii=False, indent=2)
            self.logger.info(f"统计报告已保存到: {output_file}")

        return stats
