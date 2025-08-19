#!/usr/bin/env python
"""Verilog-PPA模型训练脚本"""
import os
import sys
import argparse
import yaml
import torch
import random
import numpy as np
from transformers import AutoTokenizer

# 添加项目根目录到路径
sys.path.append("/public/home/u43077/JYX/Fine-tuning/verilog-ppa-tuning")

from config.model_config import MODEL_CONFIG
from config.train_config import TRAIN_CONFIG
from data.dataset import VerilogPPADataset, VerilogPPACollator
from model.modeling import VerilogPPAModel
from trainer.trainer import VerilogPPATrainer
from utils.logger import setup_logger


def parse_args():
    parser = argparse.ArgumentParser(description="Verilog-PPA模型训练")
    parser.add_argument("--config", type=str, default=None, help="配置文件路径")
    parser.add_argument("--model_name_or_path", type=str, default=None, help="预训练模型路径")
    parser.add_argument("--train_data", type=str, default=None, help="训练数据路径")
    parser.add_argument("--val_data", type=str, default=None, help="验证数据路径")
    parser.add_argument("--output_dir", type=str, default=None, help="输出目录")
    parser.add_argument("--seed", type=int, default=None, help="随机种子")
    parser.add_argument("--fp16", action="store_true", help="是否使用混合精度训练")
    parser.add_argument("--resume_from_checkpoint", type=str, default=None, help="从检查点恢复训练")
    return parser.parse_args()


def set_seed(seed):
    """设置随机种子"""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def setup_distributed():
    """设置分布式训练环境"""
    if int(os.environ.get("WORLD_SIZE", 1)) > 1:
        torch.distributed.init_process_group(backend="nccl")
        torch.cuda.set_device(int(os.environ.get("LOCAL_RANK", 0)))
        return True
    return False


def main():
    """主函数"""
    is_distributed = setup_distributed()
    local_rank = int(os.environ.get("LOCAL_RANK", 0))
    is_main_process = local_rank == 0

    # 解析命令行参数
    args = parse_args()

    # 合并配置
    config = MODEL_CONFIG.copy()
    config.update(TRAIN_CONFIG)

    # 加载外部配置文件
    if args.config:
        with open(args.config, 'r', encoding='utf-8') as f:
            yaml_config = yaml.safe_load(f)
            config.update(yaml_config)

    # 用命令行参数覆盖配置
    for arg, value in vars(args).items():
        if value is not None and arg in config:
            config[arg] = value

    # 设置随机种子
    set_seed(config["seed"] + local_rank)  # 为每个进程设置不同的种子

    # 设置设备
    if is_distributed:
        device = torch.device(f"cuda:{local_rank}")
    else:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # 设置日志 - 只在主进程创建日志
    if is_main_process:
        import logging
        logger = setup_logger(
            name="main",
            level=logging.INFO,
            log_file=os.path.join(config["output_dir"], "main.log")
        )
        logger.info(f"使用设备: {device}")
        logger.info(f"配置: {config}")
        logger.info(f"分布式训练: {is_distributed}")
    else:
        logger = None

    # 加载分词器
    tokenizer = AutoTokenizer.from_pretrained(
        config["tokenizer_name_or_path"],
        padding_side=config["padding_side"],
        use_fast=True
    )

    # 确保tokenizer有pad_token
    if tokenizer.pad_token_id is None:
        tokenizer.pad_token_id = config["pad_token_id"]

    # 创建数据集
    if is_main_process:
        logger.info("加载数据集...")
    train_dataset = VerilogPPADataset(
        data_path=config["train_data_path"],
        tokenizer=tokenizer,
        ppa_metrics=config["ppa_metrics"],
        max_length=config["max_length"]
    )

    # 删除了验证集加载代码

    if is_main_process:
        logger.info(f"训练集大小: {len(train_dataset)}")

    # 创建数据收集器
    collator = VerilogPPACollator(tokenizer=tokenizer)

    # 创建模型
    if is_main_process:
        logger.info("初始化模型...")
    model = VerilogPPAModel(config)
    model.to(device)

    # 在分布式环境中使用DistributedDataParallel包装模型
    if is_distributed:
        # 移除 find_unused_parameters=True，因为与静态图不兼容
        model = torch.nn.parallel.DistributedDataParallel(
            model,
            device_ids=[local_rank],
            output_device=local_rank,
            # 移除 find_unused_parameters=True
            broadcast_buffers=False
        )
        # 设置静态图，解决LoRA+梯度检查点+DDP的兼容性问题
        model._set_static_graph()
        if is_main_process:
            logger.info("已启用静态计算图，解决LoRA与梯度检查点的兼容性问题")

    # 创建训练器
    trainer = VerilogPPATrainer(
        model=model,
        train_dataset=train_dataset,
        val_dataset=None,  # 修改为None
        tokenizer=tokenizer,
        collator=collator,
        config=config,
        output_dir=config["output_dir"],
        device=device,
        is_distributed=is_distributed,
        is_main_process=is_main_process,
        logger=logger
    )

    # 从检查点恢复 - 这里是修改的部分
    if args.resume_from_checkpoint and args.resume_from_checkpoint.lower() != "none":
        # 检查是否为完整路径
        if os.path.exists(args.resume_from_checkpoint):
            checkpoint_path = args.resume_from_checkpoint
        else:
            # 尝试添加硬编码路径前缀
            hardcoded_path = f"/public/home/u43077/JYX/checkpoints/{args.resume_from_checkpoint}"
            if os.path.exists(hardcoded_path):
                checkpoint_path = hardcoded_path
            else:
                if is_main_process:
                    logger.info(f"找不到检查点路径: {args.resume_from_checkpoint} 或 {hardcoded_path}")
                checkpoint_path = None

        if checkpoint_path:
            trainer.load_checkpoint(checkpoint_path)
            if is_main_process:
                logger.info(f"成功从检查点 {checkpoint_path} 恢复训练")
        else:
            if is_main_process:
                logger.info("未提供有效的检查点路径，将从头开始训练")
    else:
        if is_main_process:
            logger.info("未提供检查点路径，将从头开始训练")

    # 开始训练
    if is_main_process:
        logger.info("开始训练...")
    trainer.train()

    if is_main_process:
        logger.info("训练完成!")

    # 清理分布式环境
    if is_distributed:
        torch.distributed.destroy_process_group()


if __name__ == "__main__":
    main()
