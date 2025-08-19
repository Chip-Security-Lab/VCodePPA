"""双任务微调训练器"""
import os
import torch
import logging
from torch.utils.data import DataLoader
from tqdm import tqdm
from transformers import get_linear_schedule_with_warmup
from model.loss import VerilogPPALoss
from utils.logger import setup_logger


class VerilogPPATrainer:
    """Verilog-PPA训练器"""

    def __init__(
            self,
            model,
            train_dataset,
            val_dataset=None,  # 允许为None
            tokenizer=None,
            collator=None,
            config=None,
            output_dir="output",
            device=None,
            is_distributed=False,
            is_main_process=True,
            logger=None
    ):
        self.model = model
        self.train_dataset = train_dataset
        self.val_dataset = val_dataset  # 可以为None
        self.tokenizer = tokenizer
        self.collator = collator
        self.config = config
        self.output_dir = output_dir

        # 分布式训练参数
        self.is_distributed = is_distributed
        self.is_main_process = is_main_process

        # 存储设备信息到trainer
        self.device = device if device is not None else (
            torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu"))

        # 确保模型在正确的设备上
        if not is_distributed:  # DDP已经处理了设备分配
            self.model.to(self.device)

        # 创建输出目录 - 只在主进程创建
        if self.is_main_process:
            os.makedirs(output_dir, exist_ok=True)

        # 设置日志
        if logger is not None:
            self.logger = logger
        else:
            import logging
            self.logger = setup_logger(
                name="trainer",
                level=logging.INFO,
                log_file=os.path.join(output_dir, "train.log") if self.is_main_process else None
            )

        # 创建数据加载器 - 使用顺序采样器
        if self.is_distributed:
            from torch.utils.data.distributed import DistributedSampler
            # 使用确定性的顺序，而不是随机打乱
            train_sampler = DistributedSampler(
                train_dataset,
                shuffle=False,  # 不要随机打乱
                seed=config["seed"]
            )
        else:
            # 使用我们自定义的顺序采样器
            from data.dataset import GroupSequentialSampler
            train_sampler = GroupSequentialSampler(train_dataset)

            if self.is_main_process:
                self.logger.info(f"使用按组顺序采样器，共{len(train_sampler)}个样本")

        self.train_dataloader = DataLoader(
            train_dataset,
            batch_size=config["per_device_train_batch_size"],
            shuffle=False,  # 使用采样器控制顺序，不再随机打乱
            sampler=train_sampler,
            collate_fn=collator,
            num_workers=config.get("num_proc", 4),
            pin_memory=True,
        )

        # 保存采样器
        self.train_sampler = train_sampler

        # 验证集是可选的
        if self.val_dataset is not None:
            if self.is_distributed:
                val_sampler = DistributedSampler(val_dataset, shuffle=False)
            else:
                val_sampler = None

            self.val_dataloader = DataLoader(
                val_dataset,
                batch_size=config["per_device_eval_batch_size"],
                shuffle=False,
                sampler=val_sampler,
                collate_fn=collator,
                num_workers=config.get("num_proc", 4),
                pin_memory=True,
            )
            self.val_sampler = val_sampler
        else:
            self.val_dataloader = None
            self.val_sampler = None

        # 设置优化器
        self.optimizer = torch.optim.AdamW(
            self.model.parameters(),
            lr=config["learning_rate"],
            weight_decay=config["weight_decay"],
        )

        # 计算训练步数
        num_update_steps_per_epoch = len(self.train_dataloader) // config["gradient_accumulation_steps"]
        self.max_train_steps = config["num_train_epochs"] * num_update_steps_per_epoch

        # 学习率调度器
        self.lr_scheduler = get_linear_schedule_with_warmup(
            self.optimizer,
            num_warmup_steps=int(self.max_train_steps * config["warmup_ratio"]),
            num_training_steps=self.max_train_steps,
        )

        # 损失函数
        self.loss_fn = VerilogPPALoss(config)

        # 训练状态
        self.global_step = 0
        self.best_loss = float('inf')  # 不再使用验证损失

    def train(self):
        """执行训练循环"""
        if self.is_main_process:
            self.logger.info("开始训练...")
        self.model.train()

        # 创建进度条 - 只在主进程显示
        if self.is_main_process:
            progress_bar = tqdm(total=self.max_train_steps, desc="Training")
            # 根据已恢复的global_step更新进度条
            progress_bar.update(self.global_step)

        # 计算当前应该从哪个epoch和样本开始
        steps_per_epoch = len(self.train_dataloader) // self.config["gradient_accumulation_steps"]
        current_epoch = self.global_step // steps_per_epoch
        current_step_in_epoch = self.global_step % steps_per_epoch

        # 将steps_per_epoch保存到配置中，供损失函数使用
        self.config["steps_per_epoch"] = steps_per_epoch

        if self.is_main_process:
            self.logger.info(f"从epoch {current_epoch + 1}的第{current_step_in_epoch}步恢复训练")

        # 添加设计类型统计计数器
        design_type_counts = {"combinational": 0, "sequential": 0, "unknown": 0}
        epoch_design_type_counts = {"combinational": 0, "sequential": 0, "unknown": 0}

        # 训练循环
        for epoch in range(current_epoch, self.config["num_train_epochs"]):
            # 在每个epoch开始时设置采样器的epoch
            if self.is_distributed and self.train_sampler:
                self.train_sampler.set_epoch(epoch)

            if self.is_main_process:
                self.logger.info(f"开始第 {epoch + 1}/{self.config['num_train_epochs']} 轮训练")

            # 重置每个epoch的设计类型计数
            epoch_design_type_counts = {"combinational": 0, "sequential": 0, "unknown": 0}

            # 跟踪每个epoch的训练损失
            epoch_loss = 0.0
            steps_in_epoch = 0

            # 用于跳过已处理的步骤
            skip_steps = current_step_in_epoch if epoch == current_epoch else 0

            # 累积当前step的设计类型统计
            step_batch_stats = {"combinational": 0, "sequential": 0, "unknown": 0}

            for step, batch in enumerate(self.train_dataloader):
                # 跳过已经处理过的步骤
                if step < skip_steps:
                    continue

                # 将批次移到设备上
                batch = {k: v.to(self.device) if isinstance(v, torch.Tensor) else v
                         for k, v in batch.items()}

                # 前向传播
                outputs = self.model(**batch)

                # 计算损失
                loss, loss_dict = self.loss_fn(outputs)

                # 累计epoch损失
                epoch_loss += loss.item()
                steps_in_epoch += 1

                # 梯度累积
                loss = loss / self.config["gradient_accumulation_steps"]
                loss.backward()

                # 累积设计类型统计 - 在每个梯度累积步骤中都收集
                if "design_types" in loss_dict:
                    design_types_str = loss_dict["design_types"]
                    types_list = design_types_str.split(",")
                    for dt in types_list:
                        dt = dt.strip()
                        if dt in ["combinational", "sequential"]:
                            step_batch_stats[dt] += 1
                        else:
                            step_batch_stats["unknown"] += 1

                # 每 gradient_accumulation_steps 步更新一次参数
                if (step + 1) % self.config["gradient_accumulation_steps"] == 0:
                    self.optimizer.step()
                    self.lr_scheduler.step()
                    self.optimizer.zero_grad()

                    # 如果是分布式训练，收集所有进程的设计类型统计
                    if self.is_distributed:
                        # 将字典转换为tensor以便通信
                        stats_tensor = torch.tensor(
                            [step_batch_stats["combinational"],
                             step_batch_stats["sequential"],
                             step_batch_stats["unknown"]],
                            device=self.device
                        )

                        # 在所有进程间求和
                        torch.distributed.all_reduce(stats_tensor, op=torch.distributed.ReduceOp.SUM)

                        # 更新本地统计
                        step_batch_stats["combinational"] = stats_tensor[0].item()
                        step_batch_stats["sequential"] = stats_tensor[1].item()
                        step_batch_stats["unknown"] = stats_tensor[2].item()

                    # 更新全局设计类型统计
                    design_type_counts["combinational"] += step_batch_stats["combinational"]
                    design_type_counts["sequential"] += step_batch_stats["sequential"]
                    design_type_counts["unknown"] += step_batch_stats["unknown"]

                    # 更新epoch设计类型统计
                    epoch_design_type_counts["combinational"] += step_batch_stats["combinational"]
                    epoch_design_type_counts["sequential"] += step_batch_stats["sequential"]
                    epoch_design_type_counts["unknown"] += step_batch_stats["unknown"]

                    # 更新全局步数
                    self.global_step += 1

                    # 更新损失函数中的global_step
                    if hasattr(self.loss_fn, 'global_step'):
                        self.loss_fn.global_step = self.global_step

                    if self.is_main_process:
                        progress_bar.update(1)

                    # 记录训练信息 - 只在主进程记录
                    if self.is_main_process and self.global_step % self.config["logging_steps"] == 0:
                        # 获取当前批次的文件名和设计类型
                        file_name = "unknown_file"
                        design_type = "未知"
                        if "file_name" in batch:
                            file_name = batch["file_name"][0]  # 获取批次中第一个文件名
                        if "design_type" in batch:
                            design_type = batch["design_type"][0]  # 获取批次中第一个设计类型

                        # 检查是否是种子文件
                        is_seed = False
                        if "is_seed" in batch:
                            is_seed = batch["is_seed"][0]

                        seed_indicator = "【种子】" if is_seed else "【变体】"

                        log_str = f"Step {self.global_step}/{self.max_train_steps}, 当前文件: {seed_indicator}{file_name}, 设计类型: {design_type}, "
                        log_str += ", ".join(
                            [f"{k}: {v:.4f}" if isinstance(v, (int, float)) else f"{k}: {v}" for k, v in
                             loss_dict.items() if k != "design_types"])

                        # 添加本批次设计类型统计
                        log_str += f", 本批次设计类型: [组合:{step_batch_stats['combinational']}, 时序:{step_batch_stats['sequential']}, 未知:{step_batch_stats['unknown']}]"

                        # 添加设计类型总计数
                        log_str += f", 总设计类型统计: [组合:{design_type_counts['combinational']}, 时序:{design_type_counts['sequential']}, 未知:{design_type_counts['unknown']}]"
                        log_str += f", 当前epoch设计类型统计: [组合:{epoch_design_type_counts['combinational']}, 时序:{epoch_design_type_counts['sequential']}, 未知:{epoch_design_type_counts['unknown']}]"

                        self.logger.info(log_str)

                    # 重置当前step的累积统计
                    step_batch_stats = {"combinational": 0, "sequential": 0, "unknown": 0}

                    # 按步数保存模型 - 只在主进程保存
                    if self.is_main_process and self.config["save_strategy"] == "steps" and self.global_step % \
                            self.config["save_steps"] == 0:
                        self.save_checkpoint(f"checkpoint-{self.global_step}")
                        self.logger.info(f"保存检查点 checkpoint-{self.global_step}")

                    # 达到最大步数时退出
                    if self.global_step >= self.max_train_steps:
                        break

            # 每个epoch结束后记录平均损失
            if self.is_main_process and steps_in_epoch > 0:
                avg_epoch_loss = epoch_loss / steps_in_epoch
                self.logger.info(
                    f"Epoch {epoch + 1} 平均损失: {avg_epoch_loss:.4f}, 设计类型统计: [组合:{epoch_design_type_counts['combinational']}, 时序:{epoch_design_type_counts['sequential']}, 未知:{epoch_design_type_counts['unknown']}]")

                # 按轮次保存模型 - 只在主进程保存
                if self.config["save_strategy"] == "epoch":
                    self.save_checkpoint(f"checkpoint-epoch-{epoch + 1}")
                    self.logger.info(f"保存轮次检查点 checkpoint-epoch-{epoch + 1}")

            # 每个epoch结束后，重置skip_steps
            current_step_in_epoch = 0

            # 达到最大步数时退出
            if self.global_step >= self.max_train_steps:
                break

        # 保存最终模型 - 只在主进程保存
        if self.is_main_process:
            self.save_checkpoint("checkpoint-final")
            self.logger.info(
                f"训练完成！总设计类型统计: [组合:{design_type_counts['combinational']}, 时序:{design_type_counts['sequential']}, 未知:{design_type_counts['unknown']}]")

    def evaluate(self):
        """在验证集上评估模型"""
        if self.is_main_process:
            self.logger.info("开始验证集评估...")
        self.model.eval()

        total_loss = 0.0
        metrics_sum = {
            "lm_loss": 0.0,
            "ppa_mse_loss": 0.0,
            "contrastive_loss": 0.0,
        }

        with torch.no_grad():
            for batch in tqdm(self.val_dataloader, desc="Evaluating", disable=not self.is_main_process):
                # 将批次移到设备上
                batch = {k: v.to(self.device) if isinstance(v, torch.Tensor) else v
                         for k, v in batch.items()}

                # 前向传播
                outputs = self.model(**batch)

                # 计算损失
                loss, loss_dict = self.loss_fn(outputs)
                total_loss += loss.item()

                # 累加各损失值
                for k, v in loss_dict.items():
                    if k in metrics_sum:
                        metrics_sum[k] += v

        # 在分布式环境中，收集所有进程的评估结果
        if self.is_distributed:
            # 收集损失
            loss_tensor = torch.tensor([total_loss]).to(self.device)
            torch.distributed.all_reduce(loss_tensor)
            total_loss = loss_tensor.item() / torch.distributed.get_world_size()

            # 收集指标
            for k in metrics_sum:
                metric_tensor = torch.tensor([metrics_sum[k]]).to(self.device)
                torch.distributed.all_reduce(metric_tensor)
                metrics_sum[k] = metric_tensor.item() / torch.distributed.get_world_size()

        # 计算平均损失和指标
        avg_loss = total_loss / len(self.val_dataloader)
        avg_metrics = {k: v / len(self.val_dataloader) for k, v in metrics_sum.items()}

        # 记录评估结果 - 只在主进程记录
        if self.is_main_process:
            log_str = f"验证结果: 总损失 = {avg_loss:.4f}, "
            log_str += ", ".join([f"{k} = {v:.4f}" for k, v in avg_metrics.items()])
            self.logger.info(log_str)

        return avg_loss, avg_metrics

    def save_checkpoint(self, checkpoint_name):
        """保存模型检查点 - 增强版本，添加错误处理和安全保存"""
        # 使用硬编码的路径
        checkpoint_base_dir = "/public/home/u43077/JYX/checkpoints"
        checkpoint_dir = os.path.join(checkpoint_base_dir, checkpoint_name)
        os.makedirs(checkpoint_dir, exist_ok=True)

        try:
            # 直接保存完整模型状态字典
            if hasattr(self.model, "module"):  # 分布式训练
                model_state_dict = self.model.module.state_dict()
            else:  # 非分布式训练
                model_state_dict = self.model.state_dict()

            # 使用临时文件先保存，再移动，避免文件损坏
            temp_file = os.path.join(checkpoint_dir, "pytorch_model.bin.tmp")

            # 使用旧的序列化格式，通常更稳定
            torch.save(
                model_state_dict,
                temp_file,
                _use_new_zipfile_serialization=False
            )

            # 重命名为最终文件名
            final_file = os.path.join(checkpoint_dir, "pytorch_model.bin")
            os.replace(temp_file, final_file)

            # 保存分词器
            self.tokenizer.save_pretrained(checkpoint_dir)

            # 保存训练状态 - 也使用临时文件策略
            trainer_state_temp = os.path.join(checkpoint_dir, "trainer_state.pt.tmp")
            torch.save({
                'global_step': self.global_step,
                'best_val_loss': self.best_loss,
                'optimizer': self.optimizer.state_dict(),
                'lr_scheduler': self.lr_scheduler.state_dict(),
            }, trainer_state_temp, _use_new_zipfile_serialization=False)

            # 重命名为最终文件名
            trainer_state_file = os.path.join(checkpoint_dir, "trainer_state.pt")
            os.replace(trainer_state_temp, trainer_state_file)

            self.logger.info(f"保存检查点到 {checkpoint_dir}")

            # 创建一个引用在原始输出目录
            try:
                output_link_dir = os.path.join(self.output_dir, checkpoint_name)
                if not os.path.exists(output_link_dir):
                    os.makedirs(os.path.dirname(output_link_dir), exist_ok=True)
                    with open(os.path.join(self.output_dir, f"{checkpoint_name}_path.txt"), 'w') as f:
                        f.write(f"检查点实际保存在: {checkpoint_dir}")
                    self.logger.info(f"创建了检查点路径引用在: {self.output_dir}")
            except Exception as e:
                self.logger.warning(f"无法创建检查点引用: {str(e)}")

        except Exception as e:
            self.logger.error(f"保存检查点失败: {str(e)}")

            # 检查磁盘空间
            import shutil
            total, used, free = shutil.disk_usage(checkpoint_base_dir)
            self.logger.error(
                f"磁盘使用情况: 总空间={total // (1024 ** 3)}GB, 已用={used // (1024 ** 3)}GB, 可用={free // (1024 ** 3)}GB")

            # 尝试保存更小的模型状态 - 只保存关键层
            try:
                if hasattr(self.model, "module"):  # 分布式训练
                    if hasattr(self.model.module, "base_model"):
                        # 只保存LoRA参数
                        lora_state_dict = {k: v for k, v in self.model.module.state_dict().items() if "lora_" in k}
                        torch.save(lora_state_dict, os.path.join(checkpoint_dir, "lora_weights.bin"))
                        self.logger.info(f"已保存LoRA权重到 {checkpoint_dir}/lora_weights.bin")
                else:
                    if hasattr(self.model, "base_model"):
                        # 只保存LoRA参数
                        lora_state_dict = {k: v for k, v in self.model.state_dict().items() if "lora_" in k}
                        torch.save(lora_state_dict, os.path.join(checkpoint_dir, "lora_weights.bin"))
                        self.logger.info(f"已保存LoRA权重到 {checkpoint_dir}/lora_weights.bin")
            except Exception as inner_e:
                self.logger.error(f"尝试保存LoRA权重也失败: {str(inner_e)}")

    def load_checkpoint(self, checkpoint_dir):
        """从检查点加载模型"""
        if not os.path.exists(checkpoint_dir):
            self.logger.warning(f"检查点路径 {checkpoint_dir} 不存在，跳过加载")
            return

        # 清理GPU缓存
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

        self.logger.info(f"从CPU加载检查点: {checkpoint_dir}")

        # 先将模型移到CPU
        if hasattr(self.model, "module"):  # 分布式训练
            model_to_save = self.model.module
        else:
            model_to_save = self.model

        # 使用CPU加载状态字典
        state_dict = torch.load(
            os.path.join(checkpoint_dir, "pytorch_model.bin"),
            map_location="cpu",  # 强制加载到CPU
            weights_only=True  # 只加载权重，避免安全警告
        )

        # 加载状态字典
        model_to_save.load_state_dict(state_dict)

        # 加载训练状态
        trainer_state_path = os.path.join(checkpoint_dir, "trainer_state.pt")
        if os.path.exists(trainer_state_path):
            trainer_state = torch.load(trainer_state_path, map_location="cpu", weights_only=True)
            self.global_step = trainer_state["global_step"]
            self.best_loss = trainer_state.get("best_val_loss", float('inf'))
            self.optimizer.load_state_dict(trainer_state["optimizer"])
            self.lr_scheduler.load_state_dict(trainer_state["lr_scheduler"])

            # 更新损失函数中的global_step
            if hasattr(self.loss_fn, 'global_step'):
                self.loss_fn.global_step = self.global_step

        self.logger.info(f"成功从硬编码路径 {checkpoint_dir} 加载检查点")
