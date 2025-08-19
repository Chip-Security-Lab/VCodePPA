#!/usr/bin/env python
"""Verilog-PPA模型评估脚本"""
import os
import sys
import argparse
import json
import torch
import numpy as np
from tqdm import tqdm
from transformers import AutoTokenizer

# 添加项目根目录到路径
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from data.dataset import VerilogPPADataset, VerilogPPACollator
from model.modeling import VerilogPPAModel
from utils.logger import setup_logger


def parse_args():
    parser = argparse.ArgumentParser(description="Verilog-PPA模型评估")
    parser.add_argument("--model_path", type=str, required=True, help="模型路径")
    parser.add_argument("--test_data", type=str, required=True, help="测试数据路径")
    parser.add_argument("--output_file", type=str, required=True, help="评估结果输出文件")
    parser.add_argument("--batch_size", type=int, default=8, help="批处理大小")
    parser.add_argument("--max_length", type=int, default=2048, help="最大序列长度")
    parser.add_argument("--num_samples", type=int, default=None, help="评估样本数量")
    return parser.parse_args()


def evaluate_model(model, dataset, collator, output_file, batch_size=8, device=None):
    """评估模型性能"""
    if device is None:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    logger = setup_logger("evaluate")
    logger.info(f"使用设备: {device}")
    logger.info(f"数据集大小: {len(dataset)}")

    # 创建数据加载器
    from torch.utils.data import DataLoader
    dataloader = DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=False,
        collate_fn=collator
    )

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
        "ppa_mse": np.mean(np.concatenate(metrics["ppa_mse"])),
        "ppa_mae": np.mean(np.concatenate(metrics["ppa_mae"])),
        "ppa_metrics": {metric: np.mean(values) for metric, values in metrics["ppa_metrics"].items()}
    }

    # 记录评估结果
    logger.info(f"评估指标: {avg_metrics}")

    # 保存结果
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({
            "metrics": avg_metrics,
            "results": results
        }, f, indent=2)

    logger.info(f"评估结果已保存到 {output_file}")

    return avg_metrics


def main():
    """主函数"""
    # 解析命令行参数
    args = parse_args()

    # 设置设备
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # 加载分词器
    tokenizer = AutoTokenizer.from_pretrained(args.model_path)

    # 加载模型配置
    with open(os.path.join(args.model_path, "config.json"), 'r') as f:
        config = json.load(f)

    # 创建数据集
    ppa_metrics = config.get("ppa_metrics", [])
    dataset = VerilogPPADataset(
        data_path=args.test_data,
        tokenizer=tokenizer,
        ppa_metrics=ppa_metrics,
        max_length=args.max_length
    )

    # 如果指定了样本数量，则只使用部分数据
    if args.num_samples and args.num_samples < len(dataset):
        from torch.utils.data import Subset
        import random
        indices = random.sample(range(len(dataset)), args.num_samples)
        dataset = Subset(dataset, indices)

    # 创建数据收集器
    collator = VerilogPPACollator(tokenizer=tokenizer)

    # 加载模型
    model = VerilogPPAModel.from_pretrained(args.model_path)
    model.to(device)

    # 评估模型
    evaluate_model(
        model=model,
        dataset=dataset,
        collator=collator,
        output_file=args.output_file,
        batch_size=args.batch_size,
        device=device
    )


if __name__ == "__main__":
    main()
