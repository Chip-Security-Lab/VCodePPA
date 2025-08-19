"""优化器和学习率调度器实现"""
import math
import torch
from torch.optim import Optimizer
from torch.optim.lr_scheduler import LambdaLR
from transformers import AdamW, get_linear_schedule_with_warmup
from typing import List, Dict, Any, Optional, Union, Callable


def get_optimizer(
        model: torch.nn.Module,
        learning_rate: float = 5e-5,
        weight_decay: float = 0.01,
        adam_beta1: float = 0.9,
        adam_beta2: float = 0.999,
        adam_epsilon: float = 1e-8,
        lora_lr_multiplier: float = 1.0
) -> torch.optim.Optimizer:
    """
    创建优化器，支持不同学习率分组

    Args:
        model: 模型
        learning_rate: 基础学习率
        weight_decay: 权重衰减
        adam_beta1: Adam beta1参数
        adam_beta2: Adam beta2参数
        adam_epsilon: Adam epsilon参数
        lora_lr_multiplier: LoRA参数的学习率乘数

    Returns:
        torch.optim.Optimizer: 优化器
    """
    # 将参数分为三组：
    # 1. LoRA参数 (更高的学习率)
    # 2. 修正层和偏置参数 (没有权重衰减)
    # 3. 其他参数
    lora_params = {"params": [], "lr": learning_rate * lora_lr_multiplier}
    no_decay_params = {"params": [], "weight_decay": 0.0}
    other_params = {"params": []}

    for name, param in model.named_parameters():
        if not param.requires_grad:
            continue

        # LoRA参数
        if "lora_" in name:
            lora_params["params"].append(param)
        # 层归一化和偏置没有权重衰减
        elif "LayerNorm" in name or "layer_norm" in name or name.endswith("bias"):
            no_decay_params["params"].append(param)
        # 其他参数有权重衰减
        else:
            other_params["params"].append(param)

    # 创建优化器参数组
    optimizer_grouped_parameters = []

    # 只添加非空组
    if lora_params["params"]:
        optimizer_grouped_parameters.append(lora_params)
    if no_decay_params["params"]:
        optimizer_grouped_parameters.append(no_decay_params)
    if other_params["params"]:
        optimizer_grouped_parameters.append(other_params)

    # 如果所有组都是空的，使用所有参数
    if not optimizer_grouped_parameters:
        optimizer_grouped_parameters = model.parameters()

    optimizer = AdamW(
        optimizer_grouped_parameters,
        lr=learning_rate,
        betas=(adam_beta1, adam_beta2),
        eps=adam_epsilon,
        weight_decay=weight_decay,
    )

    return optimizer


def get_scheduler(
        optimizer: Optimizer,
        scheduler_type: str,
        num_training_steps: int,
        num_warmup_steps: Optional[int] = None,
        warmup_ratio: float = 0.1,
        last_epoch: int = -1
) -> torch.optim.lr_scheduler.LRScheduler:
    """
    创建学习率调度器

    Args:
        optimizer: 优化器
        scheduler_type: 调度器类型 (linear, cosine, cosine_with_restarts, polynomial, constant, constant_with_warmup)
        num_training_steps: 总训练步数
        num_warmup_steps: 预热步数
        warmup_ratio: 预热比例 (如果未提供num_warmup_steps)
        last_epoch: 上一轮次索引

    Returns:
        torch.optim.lr_scheduler: 学习率调度器
    """
    if num_warmup_steps is None:
        num_warmup_steps = int(num_training_steps * warmup_ratio)

    if scheduler_type == "linear":
        return get_linear_schedule_with_warmup(
            optimizer, num_warmup_steps=num_warmup_steps, num_training_steps=num_training_steps
        )
    elif scheduler_type == "cosine":
        return get_cosine_schedule_with_warmup(
            optimizer, num_warmup_steps=num_warmup_steps, num_training_steps=num_training_steps
        )
    elif scheduler_type == "cosine_with_restarts":
        return get_cosine_with_hard_restarts_schedule_with_warmup(
            optimizer, num_warmup_steps=num_warmup_steps, num_training_steps=num_training_steps
        )
    elif scheduler_type == "polynomial":
        return get_polynomial_decay_schedule_with_warmup(
            optimizer, num_warmup_steps=num_warmup_steps, num_training_steps=num_training_steps
        )
    elif scheduler_type == "constant":
        return get_constant_schedule(optimizer)
    elif scheduler_type == "constant_with_warmup":
        return get_constant_schedule_with_warmup(optimizer, num_warmup_steps=num_warmup_steps)
    else:
        raise ValueError(f"不支持的调度器类型: {scheduler_type}")


def get_cosine_schedule_with_warmup(
        optimizer: Optimizer, num_warmup_steps: int, num_training_steps: int, last_epoch: int = -1
):
    """
    创建带预热的余弦学习率调度器

    Args:
        optimizer: 优化器
        num_warmup_steps: 预热步数
        num_training_steps: 总训练步数
        last_epoch: 上一轮次索引

    Returns:
        LambdaLR: 学习率调度器
    """

    def lr_lambda(current_step):
        if current_step < num_warmup_steps:
            return float(current_step) / float(max(1, num_warmup_steps))
        progress = float(current_step - num_warmup_steps) / float(max(1, num_training_steps - num_warmup_steps))
        return max(0.0, 0.5 * (1.0 + math.cos(math.pi * progress)))

    return LambdaLR(optimizer, lr_lambda, last_epoch)


def get_cosine_with_hard_restarts_schedule_with_warmup(
        optimizer: Optimizer, num_warmup_steps: int, num_training_steps: int, num_cycles: int = 1, last_epoch: int = -1
):
    """
    创建带预热和硬重启的余弦学习率调度器

    Args:
        optimizer: 优化器
        num_warmup_steps: 预热步数
        num_training_steps: 总训练步数
        num_cycles: 余弦周期数
        last_epoch: 上一轮次索引

    Returns:
        LambdaLR: 学习率调度器
    """

    def lr_lambda(current_step):
        if current_step < num_warmup_steps:
            return float(current_step) / float(max(1, num_warmup_steps))
        progress = float(current_step - num_warmup_steps) / float(max(1, num_training_steps - num_warmup_steps))
        if progress >= 1.0:
            return 0.0
        return max(0.0, 0.5 * (1.0 + math.cos(math.pi * ((float(num_cycles) * progress) % 1.0))))

    return LambdaLR(optimizer, lr_lambda, last_epoch)


def get_polynomial_decay_schedule_with_warmup(
        optimizer: Optimizer, num_warmup_steps: int, num_training_steps: int, lr_end: float = 1e-7, power: float = 1.0,
        last_epoch: int = -1
):
    """
    创建带预热的多项式衰减学习率调度器

    Args:
        optimizer: 优化器
        num_warmup_steps: 预热步数
        num_training_steps: 总训练步数
        lr_end: 最终学习率
        power: 衰减幂
        last_epoch: 上一轮次索引

    Returns:
        LambdaLR: 学习率调度器
    """

    def lr_lambda(current_step):
        if current_step < num_warmup_steps:
            return float(current_step) / float(max(1, num_warmup_steps))
        elif current_step > num_training_steps:
            return lr_end / optimizer.defaults["lr"]
        else:
            lr_range = optimizer.defaults["lr"] - lr_end
            decay_steps = num_training_steps - num_warmup_steps
            pct_remaining = 1 - (current_step - num_warmup_steps) / decay_steps
            decay = lr_range * pct_remaining ** power + lr_end
            return decay / optimizer.defaults["lr"]

    return LambdaLR(optimizer, lr_lambda, last_epoch)


def get_constant_schedule(optimizer: Optimizer, last_epoch: int = -1):
    """
    创建常数学习率调度器

    Args:
        optimizer: 优化器
        last_epoch: 上一轮次索引

    Returns:
        LambdaLR: 学习率调度器
    """
    return LambdaLR(optimizer, lambda _: 1, last_epoch=last_epoch)


def get_constant_schedule_with_warmup(optimizer: Optimizer, num_warmup_steps: int, last_epoch: int = -1):
    """
    创建带预热的常数学习率调度器

    Args:
        optimizer: 优化器
        num_warmup_steps: 预热步数
        last_epoch: 上一轮次索引

    Returns:
        LambdaLR: 学习率调度器
    """

    def lr_lambda(current_step):
        if current_step < num_warmup_steps:
            return float(current_step) / float(max(1.0, num_warmup_steps))
        return 1.0

    return LambdaLR(optimizer, lr_lambda, last_epoch=last_epoch)
