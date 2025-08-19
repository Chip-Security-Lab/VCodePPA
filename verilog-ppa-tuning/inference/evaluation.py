"""Verilog代码生成和PPA预测的评估器"""
import os
import json
import torch
import numpy as np
from tqdm import tqdm
from typing import Dict, List, Any, Optional

from model.metrics import PPAMetricsCalculator, CodeGenerationMetrics


class VerilogPPAEvaluator:
    """Verilog-PPA评估器"""

    def __init__(self, logger=None):
        """
        初始化评估器

        Args:
            logger: 日志记录器
        """
        from utils.logger import setup_logger
        self.logger = logger or setup_logger("evaluator")

    def evaluate_code_generation(
            self,
            generated_codes: List[str],
            reference_codes: List[str]
    ) -> Dict[str, float]:
        """
        评估代码生成质量

        Args:
            generated_codes: 生成的代码列表
            reference_codes: 参考代码列表

        Returns:
            Dict[str, float]: 评估指标
        """
        if len(generated_codes) != len(reference_codes):
            self.logger.warning(f"生成代码数量({len(generated_codes)})与参考代码数量({len(reference_codes)})不匹配")
            # 截断到相同长度
            min_len = min(len(generated_codes), len(reference_codes))
            generated_codes = generated_codes[:min_len]
            reference_codes = reference_codes[:min_len]

        # 代码生成指标
        metrics = {}

        # 计算BLEU分数
        bleu = CodeGenerationMetrics.calculate_bleu(generated_codes, reference_codes)
        metrics["bleu"] = bleu

        # 计算代码相似度
        similarity = CodeGenerationMetrics.calculate_code_similarity(generated_codes, reference_codes)
        metrics["code_similarity"] = similarity

        # 记录评估结果
        self.logger.info(f"代码生成评估结果: BLEU={bleu:.4f}, 相似度={similarity:.4f}")

        return metrics

    def evaluate_ppa_prediction(
            self,
            predicted_ppa: List[Dict[str, float]],
            target_ppa: List[Dict[str, float]],
            ppa_metrics: List[str] = None
    ) -> Dict[str, float]:
        """
        评估PPA预测质量

        Args:
            predicted_ppa: 预测的PPA指标列表
            target_ppa: 目标PPA指标列表
            ppa_metrics: 要评估的PPA指标列表

        Returns:
            Dict[str, float]: 评估指标
        """
        if len(predicted_ppa) != len(target_ppa):
            self.logger.warning(f"预测PPA数量({len(predicted_ppa)})与目标PPA数量({len(target_ppa)})不匹配")
            # 截断到相同长度
            min_len = min(len(predicted_ppa), len(target_ppa))
            predicted_ppa = predicted_ppa[:min_len]
            target_ppa = target_ppa[:min_len]

        # 如果未指定评估指标，则使用所有可用指标
        if ppa_metrics is None:
            # 获取所有指标的并集
            ppa_metrics = set()
            for ppa in predicted_ppa + target_ppa:
                ppa_metrics.update(ppa.keys())
            ppa_metrics = sorted(list(ppa_metrics))

        # 转换为张量
        pred_tensor = torch.tensor([
            [ppa.get(metric, 0.0) for metric in ppa_metrics]
            for ppa in predicted_ppa
        ], dtype=torch.float)

        target_tensor = torch.tensor([
            [ppa.get(metric, 0.0) for metric in ppa_metrics]
            for ppa in target_ppa
        ], dtype=torch.float)

        # 计算评估指标
        metrics = PPAMetricsCalculator.calculate_metrics(pred_tensor, target_tensor)

        # 计算相对误差
        rel_metrics = PPAMetricsCalculator.calculate_relative_error(pred_tensor, target_tensor)
        metrics.update(rel_metrics)

        # 计算每个指标的评估结果
        per_metric_results = {}
        for i, metric in enumerate(ppa_metrics):
            pred_values = pred_tensor[:, i].numpy()
            target_values = target_tensor[:, i].numpy()

            # 计算MSE
            mse = np.mean((pred_values - target_values) ** 2)
            # 计算MAE
            mae = np.mean(np.abs(pred_values - target_values))
            # 计算相对误差
            rel_error = np.mean(np.abs(pred_values - target_values) / (np.abs(target_values) + 1e-10))

            per_metric_results[metric] = {
                "mse": mse,
                "mae": mae,
                "rel_error": rel_error
            }

        metrics["per_metric"] = per_metric_results

        # 记录评估结果
        self.logger.info(
            f"PPA预测评估结果: MSE={metrics['mse']:.4f}, MAE={metrics['mae']:.4f}, 相对误差={metrics['mean_rel_error']:.4f}")

        return metrics

    def evaluate_model(
            self,
            model,
            dataset,
            dataloader,
            output_file=None,
            device=None,
    ) -> Dict[str, Any]:
        """
        评估模型性能

        Args:
            model: 模型
            dataset: 数据集
            dataloader: 数据加载器
            output_file: 输出文件路径
            device: 运行设备

        Returns:
            Dict[str, Any]: 评估结果
        """
        if device is None:
            device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        self.logger.info(f"使用设备: {device}")
        self.logger.info(f"数据集大小: {len(dataset)}")

        # 评估指标
        metrics = {
            "ppa_mse": [],
            "ppa_mae": [],
            "ppa_metrics": {metric: [] for metric in dataset.ppa_metrics}
        }

        # 结果列表
        results = []

        # 将模型设置为评估模式
        model.eval()

        # 对比学习指标
        contrastive_metrics = []

        # 评估循环
        with torch.no_grad():
            for batch in tqdm(dataloader, desc="Evaluating"):
                # 将批次移到设备上
                batch = {k: v.to(device) if isinstance(v, torch.Tensor) else v
                         for k, v in batch.items()}

                # 前向传播
                outputs = model(**batch)

                # 获取PPA预测值
                if hasattr(model, "ppa_head") and "ppa_values" in batch:
                    ppa_pred = outputs.get("ppa_pred")
                    ppa_true = batch["ppa_values"]

                    # 计算MSE和MAE
                    mse = torch.mean((ppa_pred - ppa_true) ** 2, dim=0)
                    mae = torch.mean(torch.abs(ppa_pred - ppa_true), dim=0)

                    metrics["ppa_mse"].append(mse.cpu().numpy())
                    metrics["ppa_mae"].append(mae.cpu().numpy())

                    # 计算每个PPA指标的误差
                    for i, metric in enumerate(dataset.ppa_metrics):
                        metric_mse = ((ppa_pred[:, i] - ppa_true[:, i]) ** 2).mean().item()
                        metrics["ppa_metrics"][metric].append(metric_mse)

                # 如果有对比学习嵌入，计算对比学习指标
                if hasattr(model, "code_proj") and hasattr(model, "ppa_proj") and "ppa_values" in batch:
                    # 获取代码和PPA的嵌入表示
                    hidden_states = outputs["hidden_states"][-1]
                    code_hidden = hidden_states[:, -1]
                    code_emb = model.code_proj(code_hidden)
                    ppa_emb = model.ppa_proj(ppa_true)

                    # 计算对比学习指标
                    from model.metrics import ContrastiveLearningMetrics
                    batch_metrics = ContrastiveLearningMetrics.calculate_ranking_metrics(code_emb, ppa_emb)
                    contrastive_metrics.append(batch_metrics)

                # 保存结果
                for i in range(len(batch["original_code"])):
                    # 反归一化预测的PPA值
                    pred_ppa = {}
                    true_ppa = {}

                    for j, metric in enumerate(dataset.ppa_metrics):
                        if metric in dataset.ppa_stats:
                            # 使用Z-score反归一化
                            pred_norm = ppa_pred[i, j].item()
                            true_norm = ppa_true[i, j].item()

                            mean = dataset.ppa_stats[metric]["mean"]
                            std = dataset.ppa_stats[metric]["std"]

                            pred_ppa[metric] = pred_norm * std + mean
                            true_ppa[metric] = true_norm * std + mean
                        else:
                            pred_ppa[metric] = ppa_pred[i, j].item()
                            true_ppa[metric] = ppa_true[i, j].item()

                    # 添加到结果列表
                    results.append({
                        "code": batch["original_code"][i],
                        "raw_ppa": batch["raw_ppa"][i],
                        "predicted_ppa": pred_ppa,
                        "true_ppa": true_ppa
                    })

        # 计算平均指标
        avg_metrics = {
            "ppa_mse": float(np.mean(np.concatenate(metrics["ppa_mse"]))),
            "ppa_mae": float(np.mean(np.concatenate(metrics["ppa_mae"]))),
            "ppa_metrics": {metric: float(np.mean(values)) for metric, values in metrics["ppa_metrics"].items()}
        }

        # 加入对比学习指标
        if contrastive_metrics:
            avg_contrastive = {}
            for key in contrastive_metrics[0].keys():
                avg_contrastive[key] = float(np.mean([m[key] for m in contrastive_metrics]))
            avg_metrics["contrastive"] = avg_contrastive

        # 记录评估结果
        self.logger.info(f"评估指标: {avg_metrics}")

        # 保存结果
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump({
                    "metrics": avg_metrics,
                    "results": results
                }, f, ensure_ascii=False, indent=2)

            self.logger.info(f"评估结果已保存到 {output_file}")

        return {
            "metrics": avg_metrics,
            "results": results
        }
