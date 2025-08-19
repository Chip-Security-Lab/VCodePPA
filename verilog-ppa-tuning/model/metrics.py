"""Verilog代码和PPA预测的评估指标"""
import torch
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from typing import Dict, List, Tuple, Any, Optional


class PPAMetricsCalculator:
    """PPA预测指标计算器"""

    @staticmethod
    def calculate_metrics(predictions: torch.Tensor, targets: torch.Tensor) -> Dict[str, float]:
        """
        计算PPA预测的评估指标

        Args:
            predictions: 预测值 [batch_size, num_metrics]
            targets: 目标值 [batch_size, num_metrics]

        Returns:
            Dict[str, float]: 评估指标字典
        """
        # 转换为numpy数组
        if isinstance(predictions, torch.Tensor):
            predictions = predictions.detach().cpu().numpy()
        if isinstance(targets, torch.Tensor):
            targets = targets.detach().cpu().numpy()

        # 计算总体指标
        mse = mean_squared_error(targets, predictions)
        rmse = np.sqrt(mse)
        mae = mean_absolute_error(targets, predictions)
        r2 = r2_score(targets, predictions)

        # 计算每个维度的指标
        per_dim_mse = np.mean((predictions - targets) ** 2, axis=0)
        per_dim_mae = np.mean(np.abs(predictions - targets), axis=0)

        metrics = {
            'mse': mse,
            'rmse': rmse,
            'mae': mae,
            'r2': r2,
            'per_dim_mse': per_dim_mse.tolist(),
            'per_dim_mae': per_dim_mae.tolist()
        }

        return metrics

    @staticmethod
    def calculate_relative_error(predictions: torch.Tensor, targets: torch.Tensor) -> Dict[str, float]:
        """
        计算PPA预测的相对误差

        Args:
            predictions: 预测值 [batch_size, num_metrics]
            targets: 目标值 [batch_size, num_metrics]

        Returns:
            Dict[str, float]: 相对误差指标
        """
        # 转换为numpy数组
        if isinstance(predictions, torch.Tensor):
            predictions = predictions.detach().cpu().numpy()
        if isinstance(targets, torch.Tensor):
            targets = targets.detach().cpu().numpy()

        # 避免除以零
        epsilon = 1e-10

        # 计算相对误差
        rel_error = np.abs(predictions - targets) / (np.abs(targets) + epsilon)

        # 计算平均相对误差
        mean_rel_error = np.mean(rel_error)
        median_rel_error = np.median(rel_error)

        # 每个维度的相对误差
        per_dim_rel_error = np.mean(rel_error, axis=0)

        metrics = {
            'mean_rel_error': mean_rel_error,
            'median_rel_error': median_rel_error,
            'per_dim_rel_error': per_dim_rel_error.tolist()
        }

        return metrics


class CodeGenerationMetrics:
    """代码生成评估指标"""

    @staticmethod
    def calculate_bleu(predictions: List[str], references: List[str]) -> float:
        """
        计算BLEU分数

        Args:
            predictions: 预测的代码
            references: 参考代码

        Returns:
            float: BLEU分数
        """
        from nltk.translate.bleu_score import sentence_bleu, SmoothingFunction

        smooth = SmoothingFunction().method1
        bleu_scores = []

        for pred, ref in zip(predictions, references):
            # 分词
            pred_tokens = list(pred)
            ref_tokens = list(ref)

            # 计算BLEU
            score = sentence_bleu([ref_tokens], pred_tokens, smoothing_function=smooth)
            bleu_scores.append(score)

        return sum(bleu_scores) / len(bleu_scores) if bleu_scores else 0.0

    @staticmethod
    def calculate_code_similarity(predictions: List[str], references: List[str]) -> float:
        """
        计算代码相似度

        Args:
            predictions: 预测的代码
            references: 参考代码

        Returns:
            float: 相似度分数
        """

        def preprocess_code(code):
            # 移除注释
            code = re.sub(r'//.*?\n', '\n', code)
            code = re.sub(r'/\*[\s\S]*?\*/', '', code)
            # 移除空白行
            code = re.sub(r'\n\s*\n', '\n', code)
            # 移除空格
            code = re.sub(r'\s+', ' ', code).strip()
            return code

        import re
        from difflib import SequenceMatcher

        similarities = []

        for pred, ref in zip(predictions, references):
            # 预处理代码
            pred_clean = preprocess_code(pred)
            ref_clean = preprocess_code(ref)

            # 计算相似度
            similarity = SequenceMatcher(None, pred_clean, ref_clean).ratio()
            similarities.append(similarity)

        return sum(similarities) / len(similarities) if similarities else 0.0


class ContrastiveLearningMetrics:
    """对比学习评估指标"""

    @staticmethod
    def calculate_ranking_metrics(
            code_embeddings: torch.Tensor,
            ppa_embeddings: torch.Tensor
    ) -> Dict[str, float]:
        """
        计算代码-PPA对的排名指标

        Args:
            code_embeddings: 代码嵌入 [batch_size, embedding_dim]
            ppa_embeddings: PPA指标嵌入 [batch_size, embedding_dim]

        Returns:
            Dict[str, float]: 排名指标
        """
        # 归一化嵌入
        code_embeddings = torch.nn.functional.normalize(code_embeddings, p=2, dim=1)
        ppa_embeddings = torch.nn.functional.normalize(ppa_embeddings, p=2, dim=1)

        # 计算余弦相似度矩阵
        sim_matrix = torch.matmul(code_embeddings, ppa_embeddings.t())

        # 分别计算代码到PPA和PPA到代码的排名
        batch_size = code_embeddings.size(0)

        # 创建目标标签（对角线）
        targets = torch.arange(batch_size, device=code_embeddings.device)

        # 计算代码到PPA的排名
        code_to_ppa_ranks = []
        for i in range(batch_size):
            # 获取当前代码与所有PPA的相似度
            similarities = sim_matrix[i]
            # 获取相似度降序排序的索引
            _, indices = torch.sort(similarities, descending=True)
            # 找出匹配PPA的排名
            rank = torch.where(indices == i)[0].item() + 1
            code_to_ppa_ranks.append(rank)

        # 计算PPA到代码的排名
        ppa_to_code_ranks = []
        for i in range(batch_size):
            # 获取当前PPA与所有代码的相似度
            similarities = sim_matrix[:, i]
            # 获取相似度降序排序的索引
            _, indices = torch.sort(similarities, descending=True)
            # 找出匹配代码的排名
            rank = torch.where(indices == i)[0].item() + 1
            ppa_to_code_ranks.append(rank)

        # 计算MRR (Mean Reciprocal Rank)
        code_to_ppa_mrr = np.mean([1.0 / rank for rank in code_to_ppa_ranks])
        ppa_to_code_mrr = np.mean([1.0 / rank for rank in ppa_to_code_ranks])

        # 计算Recall@K
        def recall_at_k(ranks, k):
            return sum(1 for rank in ranks if rank <= k) / len(ranks)

        metrics = {
            'code_to_ppa_mrr': code_to_ppa_mrr,
            'ppa_to_code_mrr': ppa_to_code_mrr,
            'avg_mrr': (code_to_ppa_mrr + ppa_to_code_mrr) / 2,
            'code_to_ppa_r@1': recall_at_k(code_to_ppa_ranks, 1),
            'code_to_ppa_r@5': recall_at_k(code_to_ppa_ranks, 5),
            'code_to_ppa_r@10': recall_at_k(code_to_ppa_ranks, 10),
            'ppa_to_code_r@1': recall_at_k(ppa_to_code_ranks, 1),
            'ppa_to_code_r@5': recall_at_k(ppa_to_code_ranks, 5),
            'ppa_to_code_r@10': recall_at_k(ppa_to_code_ranks, 10),
        }

        return metrics
