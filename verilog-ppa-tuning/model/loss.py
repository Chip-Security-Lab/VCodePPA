"""双任务损失函数，包括对比学习"""
import torch
import torch.nn as nn
import torch.nn.functional as F

"""双任务损失函数，包括对比学习"""
import torch
import torch.nn as nn
import torch.nn.functional as F


class VerilogPPALoss(nn.Module):
    """Verilog-PPA模型的损失函数"""

    def __init__(self, config):
        super().__init__()
        self.code_generation_weight = config.get("code_generation_weight", 1.0)
        self.ppa_prediction_weight = config.get("ppa_prediction_weight", 0.5)
        self.contrastive_weight = config.get("contrastive_weight", 0.3)
        self.ppa_sensitivity = config.get("ppa_sensitivity", 0.5)  # 控制对PPA分数的敏感度
        self.config = config  # 保存配置以便访问PPA指标

        # PPA指标权重定义
        self.ppa_metric_weights = {
            "combinational": {
                "lut": 0.20,  # 面积很重要
                "ff": 0.05,  # FF在组合逻辑中不太重要
                "io": 0.10,
                "cell_count": 0.25,  # 总单元数重要
                "max_freq": 0.0,  # 组合逻辑中频率不太相关
                "reg_to_reg_delay": 0.0,  # 无寄存器路径
                "end_to_end_delay": 0.25,  # 端到端延迟很重要
                "total_power": 0.15  # 功耗中等重要性
            },
            "sequential": {
                "lut": 0.15,  # 面积中等重要
                "ff": 0.15,  # FF在时序逻辑中重要
                "io": 0.05,
                "cell_count": 0.15,  # 总单元数较重要
                "max_freq": 0.25,  # 频率非常重要
                "reg_to_reg_delay": 0.2,  # 寄存器间延迟重要
                "end_to_end_delay": 0.0,  # 端到端延迟次要
                "total_power": 0.10  # 功耗中等重要性
            }
        }

        # 哪些指标是越高越好
        self.better_higher = {"max_freq"}

        # 添加进度相关参数
        self.global_step = 0
        # 默认值：前10%的训练时间主要针对PPA预测头训练
        self.warmup_steps = config.get("ppa_warmup_steps", int(0.1 * config.get("num_train_epochs", 3) *
                                                               config.get("steps_per_epoch", 1000)))

        # 新增: 添加PPA指标的预设范围，用于归一化
        self.ppa_ranges = {
            "lut": (-3.0, 3.0),
            "ff": (-3.0, 3.0),
            "io": (-2.0, 2.0),
            "cell_count": (-3.0, 3.0),
            "max_freq": (-2.0, 2.0),
            "reg_to_reg_delay": (-2.0, 2.0),
            "end_to_end_delay": (-2.0, 2.0),
            "total_power": (-2.0, 2.0)
        }

        # 新增: 全局PPA统计跟踪
        self.ppa_stats = {
            "min": {},  # 每个指标的最小值
            "max": {},  # 每个指标的最大值
            "mean": {},  # 每个指标的均值
            "std": {},  # 每个指标的标准差
            "count": 0  # 处理的批次数
        }

    def process_ppa_metrics(self, ppa_pred, metrics, design_types=None):
        """
        处理PPA指标并计算综合评分 - 改进版，使用预设范围或全局统计进行归一化

        Args:
            ppa_pred: 预测的PPA指标 [batch_size, num_metrics]
            metrics: 指标名称列表
            design_types: 每个样本的设计类型列表 ['sequential', 'combinational', ...]
        """
        batch_size = ppa_pred.size(0)
        num_metrics = min(len(metrics), ppa_pred.size(1))
        device = ppa_pred.device

        # 初始化调试信息
        debug_info = {
            "raw_values": {},
            "normalized": {},
            "direction_adjusted": {},
            "weighted": {},
            "design_types": [],
        }

        # 初始化批次得分
        batch_scores = torch.zeros(batch_size, device=device)

        # 存储批次平均的原始值
        for i, metric in enumerate(metrics[:num_metrics]):
            if i < ppa_pred.size(1):
                debug_info["raw_values"][metric] = ppa_pred[:, i].mean().item()

        # 逐样本处理
        for i in range(batch_size):
            # 确定当前样本的设计类型
            if design_types is not None and i < len(design_types):
                curr_design_type = design_types[i] if design_types[i] in ['sequential',
                                                                          'combinational'] else 'combinational'
            else:
                # 如果没有提供设计类型，使用单样本判断方法
                curr_design_type = self._determine_single_design_type(ppa_pred[i:i + 1], metrics)

            debug_info["design_types"].append(curr_design_type)

            # 基于设计类型选择权重
            weights = {metric: self.ppa_metric_weights[curr_design_type].get(metric, 0.1)
                       for metric in metrics[:num_metrics]}

            total_weight = sum(weights.values())

            # 处理单个样本的得分
            sample_score = 0.0

            for j, metric in enumerate(metrics[:num_metrics]):
                if j >= ppa_pred.size(1):
                    continue

                # 获取当前指标的值
                value = ppa_pred[i, j].clone()

                # 跳过无效值
                if torch.isnan(value) or torch.isinf(value):
                    continue

                # 1. 归一化处理
                if metric in self.ppa_ranges:
                    # 使用预设范围归一化
                    min_val, max_val = self.ppa_ranges[metric]
                    normalized = torch.clamp((value - min_val) / (max_val - min_val), 0.0, 1.0)
                elif self.ppa_stats["count"] > 5 and metric in self.ppa_stats["mean"]:
                    # 使用累积的均值和标准差进行Z-score归一化
                    mean_val = self.ppa_stats["mean"][metric]
                    std_val = self.ppa_stats["std"][metric]
                    z_score = (value - mean_val) / (std_val + 1e-8)
                    # 使用sigmoid将Z-score压缩到(0,1)范围
                    normalized = torch.sigmoid(z_score)
                elif metric in self.ppa_stats["min"] and metric in self.ppa_stats["max"]:
                    # 使用观察到的全局最大最小值
                    min_val = self.ppa_stats["min"][metric]
                    max_val = self.ppa_stats["max"][metric]
                    # 添加一些余量避免边界情况
                    range_size = max(max_val - min_val, 0.2)  # 确保至少0.2的范围
                    min_val -= range_size * 0.1
                    max_val += range_size * 0.1
                    normalized = torch.clamp((value - min_val) / (max_val - min_val + 1e-8), 0.0, 1.0)
                else:
                    # 无法归一化时，使用默认值
                    normalized = torch.tensor(0.5, device=device)

                # 更新调试信息（仅记录第一个样本的值）
                if i == 0:
                    if metric not in debug_info["normalized"]:
                        debug_info["normalized"][metric] = normalized.item()

                # 2. 根据指标方向调整
                if metric in self.better_higher:
                    # 越高越好 - 添加非线性强调
                    direction_adjusted = torch.pow(normalized, 1.2)  # 幂函数强调高值
                else:
                    # 越低越好 - 翻转值并添加非线性强调
                    direction_adjusted = torch.pow(1.0 - normalized, 1.2)  # 幂函数强调低值

                # 更新调试信息（仅记录第一个样本的值）
                if i == 0:
                    if metric not in debug_info["direction_adjusted"]:
                        debug_info["direction_adjusted"][metric] = direction_adjusted.item()

                # 3. 应用权重
                weight = weights[metric] / total_weight  # 归一化权重确保总和为1
                weighted_score = direction_adjusted * weight

                # 更新调试信息（仅记录第一个样本的值）
                if i == 0:
                    if metric not in debug_info["weighted"]:
                        debug_info["weighted"][metric] = weighted_score.item()

                # 累加到样本分数
                sample_score += weighted_score

            # 使用tanh函数将分数映射到(-1,1)范围，增强区分度
            sample_score = torch.tanh(sample_score * 2.0)  # *2.0放大差异

            # 在早期训练阶段添加少量随机噪声促进探索
            if self.training and self.global_step < 100:
                # 从0.3开始线性衰减到0
                noise_scale = max(0.0, 0.3 - self.global_step / 333.0)
                noise = (torch.rand(1, device=device) * 2 - 1) * noise_scale
                sample_score = torch.clamp(sample_score + noise, -1.0, 1.0)

            # 将样本分数添加到批次分数
            batch_scores[i] = sample_score

        # 更新处理的批次计数
        self.ppa_stats["count"] += 1

        # 计算最终分数（批次平均）
        final_score = batch_scores.mean()

        return final_score, debug_info

    def _determine_single_design_type(self, ppa_pred, metrics):
        """
        判断单个样本的设计类型 - 简化版只检查FF值

        Args:
            ppa_pred: 单个样本的PPA预测 [1, num_metrics]
            metrics: 指标名称列表

        Returns:
            str: 'sequential' 或 'combinational'
        """
        # 默认为组合逻辑
        design_type = 'combinational'

        # 检查FF值 - 简化判断逻辑
        ff_idx = metrics.index('ff') if 'ff' in metrics else -1
        if ff_idx >= 0 and ff_idx < ppa_pred.size(1):
            # 对于归一化后的FF值，使用较宽松的阈值
            has_ff = ppa_pred[0, ff_idx].item() > -1.0
            if has_ff:
                design_type = 'sequential'

        return design_type

    def calculate_weighted_ppa_loss(self, ppa_pred, ppa_true, metrics, design_types=None):
        """
        计算加权PPA预测损失 - 使用样本级别的设计类型判断

        Args:
            ppa_pred: 预测的PPA指标 [batch_size, num_metrics]
            ppa_true: 真实的PPA指标 [batch_size, num_metrics]
            metrics: 指标名称列表
            design_types: 可选的预定义设计类型列表

        Returns:
            loss: 加权损失
            metric_losses: 各指标的损失
            normalized_weights: 归一化的权重
        """
        batch_size = ppa_pred.size(0)
        num_metrics = min(len(metrics), ppa_pred.size(1), ppa_true.size(1))
        device = ppa_pred.device

        # 初始化
        total_loss = torch.tensor(0.0, device=device)
        metric_losses = {}
        normalized_weights = {}

        # 样本级别的处理
        for b in range(batch_size):
            # 确定当前样本的设计类型
            if design_types is not None and b < len(design_types):
                curr_design_type = design_types[b]
            else:
                # 使用单样本判断方法确定设计类型
                curr_design_type = self._determine_single_design_type(ppa_pred[b:b + 1], metrics)

            # 基于设计类型选择权重
            weights = {metric: self.ppa_metric_weights[curr_design_type].get(metric, 0.1)
                       for metric in metrics[:num_metrics]}

            # 计算权重总和
            total_weight = sum(weights.values())

            # 初始化样本损失
            sample_loss = torch.tensor(0.0, device=device)

            # 对每个指标计算损失
            for i, metric in enumerate(metrics[:num_metrics]):
                if i >= num_metrics:
                    continue

                # 获取当前样本的预测和真实值
                pred = ppa_pred[b, i]
                true = ppa_true[b, i]

                # 跳过无效值
                if torch.isnan(pred) or torch.isinf(pred) or torch.isnan(true) or torch.isinf(true):
                    continue

                # 计算指标损失
                metric_loss = (pred - true) ** 2

                # 应用权重
                normalized_weight = weights[metric] / total_weight
                weighted_loss = metric_loss * normalized_weight

                # 累加到样本损失
                sample_loss += weighted_loss

                # 记录第一个样本的指标损失和权重（用于日志）
                if b == 0:
                    metric_losses[metric] = metric_loss.item()
                    normalized_weights[metric] = normalized_weight

            # 累加样本损失到总损失
            total_loss += sample_loss

        # 计算平均损失
        if batch_size > 0:
            total_loss = total_loss / batch_size

        return total_loss, metric_losses, normalized_weights

    def compute_enhanced_ppa_factor(self, ppa_score, ppa_pred, metrics):
        """
        增强版PPA因子计算，考虑各指标对代码的影响

        Args:
            ppa_score: 综合PPA评分
            ppa_pred: 预测的PPA指标 [batch_size, num_metrics]
            metrics: 指标名称列表

        Returns:
            torch.Tensor: 增强版PPA因子
        """
        # 基础PPA因子（与当前相同）
        base_factor = torch.sigmoid(-ppa_score * self.ppa_sensitivity)

        # 增加对各指标的敏感性分析
        indicator_influences = {}
        for i, metric in enumerate(metrics):
            if i < ppa_pred.size(1):
                # 提取当前指标值
                value = ppa_pred[:, i].mean()

                # 确定该指标是好还是坏的信号
                is_good_signal = False
                if metric in self.better_higher:
                    # 对于"越高越好"的指标，高值是好信号
                    is_good_signal = (value > self.ppa_stats["mean"].get(metric, 0))
                else:
                    # 对于"越低越好"的指标，低值是好信号
                    is_good_signal = (value < self.ppa_stats["mean"].get(metric, 0))

                # 计算该指标对PPA因子的调整值
                metric_importance = self.ppa_metric_weights["sequential"].get(metric, 0.1)
                indicator_influences[metric] = (1.0 if is_good_signal else -1.0) * metric_importance

        # 综合各指标影响，计算调整系数（范围：0.8-1.2）
        adjustment = 1.0
        if indicator_influences:
            # 计算加权平均调整值
            avg_influence = sum(indicator_influences.values()) / len(indicator_influences)
            # 将调整限制在一个合理范围内
            adjustment = 1.0 + torch.tanh(torch.tensor(avg_influence, device=ppa_score.device)) * 0.2

        # 返回调整后的PPA因子
        enhanced_factor = base_factor * adjustment

        # 添加调试信息
        debug_info = {
            "base_factor": base_factor.item(),
            "adjustment": adjustment.item() if torch.is_tensor(adjustment) else adjustment,
            "indicator_influences": indicator_influences
        }

        return enhanced_factor, debug_info

    def forward(self, model_outputs):
        """计算渐进式PPA感知的总损失"""
        total_loss = 0.0
        loss_dict = {}

        # 计算训练进度（0到1之间）
        progress = min(1.0, self.global_step / self.warmup_steps) if hasattr(self,
                                                                             'global_step') and self.warmup_steps > 0 else 0.0

        # 代码生成损失（自回归语言模型损失）- 加入渐进式PPA感知
        if "lm_loss" in model_outputs:
            lm_loss = model_outputs["lm_loss"]

            # 基本版本 - 无PPA调整
            if "ppa_pred" not in model_outputs:
                loss_dict["lm_loss"] = lm_loss.item()
                total_loss += self.code_generation_weight * lm_loss
            else:
                # 获取预测的PPA指标
                ppa_pred = model_outputs["ppa_pred"]
                metrics = self.config.get("ppa_metrics", [])
                design_types = model_outputs.get("design_type", None)

                # 简化版：如果有raw_ppa，仅使用FF是否为0来判断设计类型
                if "raw_ppa" in model_outputs:
                    design_types = []
                    for item in model_outputs["raw_ppa"]:
                        # 简化的判断逻辑：只检查FF值是否大于0
                        if item.get("ff", 0) > 0:  # 使用get方法防止键不存在
                            design_types.append("sequential")
                        else:
                            design_types.append("combinational")

                    # 将处理后的设计类型添加到loss_dict，方便统计
                    loss_dict["design_types"] = ",".join(design_types)

                # 增强的PPA处理，带详细调试信息
                try:
                    ppa_score, debug_info = self.process_ppa_metrics(ppa_pred, metrics, design_types)

                    # 添加所有调试信息到损失字典
                    for stage, stage_info in debug_info.items():
                        if isinstance(stage_info, dict):
                            for metric, value in stage_info.items():
                                loss_dict[f"{stage}_{metric}"] = value
                        elif isinstance(stage_info, list):
                            loss_dict[f"{stage}"] = ",".join(stage_info)

                    # 确保ppa_score是标量且为浮点数
                    if not torch.is_tensor(ppa_score):
                        ppa_score = torch.tensor(ppa_score, device=ppa_pred.device)
                    ppa_score = ppa_score.float()

                    # 使用增强版PPA因子计算
                    ppa_factor, factor_debug_info = self.compute_enhanced_ppa_factor(ppa_score, ppa_pred, metrics)

                    # 添加因子调试信息到损失字典
                    loss_dict["raw_ppa_score"] = ppa_score.item()
                    loss_dict["base_ppa_factor"] = factor_debug_info["base_factor"]
                    loss_dict["ppa_adjustment"] = factor_debug_info["adjustment"]
                    loss_dict["enhanced_ppa_factor"] = ppa_factor.item()

                    # 使用渐进式权重，训练初期减少PPA因子的影响
                    progress_adjusted_factor = ppa_factor * progress
                    adjusted_weight = self.code_generation_weight * (1.0 + progress_adjusted_factor)

                    # 使用调整后的权重
                    loss_dict["lm_loss"] = lm_loss.item()
                    loss_dict["progress"] = progress
                    total_loss += adjusted_weight * lm_loss

                    # 记录各PPA指标对代码生成的影响
                    influences = factor_debug_info["indicator_influences"]
                    for metric, influence in influences.items():
                        loss_dict[f"influence_{metric}"] = influence

                    # 新增: 记录关键PPA统计信息
                    if self.global_step % 50 == 0:  # 每50步记录一次
                        for metric in metrics:
                            if metric in self.ppa_stats["mean"]:
                                loss_dict[f"ppa_stat_{metric}_mean"] = self.ppa_stats["mean"][metric]
                                loss_dict[f"ppa_stat_{metric}_std"] = self.ppa_stats["std"][metric]

                except Exception as e:
                    # 如果处理失败，回退到基本版本
                    loss_dict["lm_loss"] = lm_loss.item()
                    loss_dict["ppa_error"] = str(e)
                    total_loss += self.code_generation_weight * lm_loss

        # PPA预测MSE损失 - 使用加权损失
        if "ppa_mse_loss" in model_outputs and "ppa_pred" in model_outputs and "ppa_values" in model_outputs:
            try:
                # 尝试使用增强的加权损失
                metrics = self.config.get("ppa_metrics", [])
                ppa_pred = model_outputs["ppa_pred"]
                ppa_true = model_outputs["ppa_values"]

                ppa_loss, metric_losses, norm_weights = self.calculate_weighted_ppa_loss(ppa_pred, ppa_true, metrics)

                # 前期增加权重以加速学习
                early_boost = max(1.0, 2.0 * (1.0 - progress))
                ppa_weight = self.ppa_prediction_weight * early_boost

                # 记录各指标的损失
                loss_dict["ppa_mse_loss"] = ppa_loss.item()
                for metric, m_loss in metric_losses.items():
                    loss_dict[f"loss_{metric}"] = m_loss
                    loss_dict[f"weight_{metric}"] = norm_weights.get(metric, 0)

                loss_dict["ppa_weight"] = ppa_weight
                total_loss += ppa_weight * ppa_loss

            except Exception as e:
                # 回退到原始MSE损失
                ppa_mse_loss = model_outputs["ppa_mse_loss"]
                early_boost = max(1.0, 2.0 * (1.0 - progress))
                ppa_weight = self.ppa_prediction_weight * early_boost

                loss_dict["ppa_mse_loss"] = ppa_mse_loss.item()
                loss_dict["ppa_weight"] = ppa_weight
                loss_dict["ppa_fallback_reason"] = str(e)
                total_loss += ppa_weight * ppa_mse_loss

        elif "ppa_mse_loss" in model_outputs:
            # 使用原始MSE损失
            ppa_mse_loss = model_outputs["ppa_mse_loss"]
            early_boost = max(1.0, 2.0 * (1.0 - progress))
            ppa_weight = self.ppa_prediction_weight * early_boost

            loss_dict["ppa_mse_loss"] = ppa_mse_loss.item()
            loss_dict["ppa_weight"] = ppa_weight
            total_loss += ppa_weight * ppa_mse_loss

        # 对比学习损失
        if "contrastive_loss" in model_outputs:
            contrastive_loss = model_outputs["contrastive_loss"]
            loss_dict["contrastive_loss"] = contrastive_loss.item()
            total_loss += self.contrastive_weight * contrastive_loss

        # 增加全局步数
        self.global_step += 1

        loss_dict["total_loss"] = total_loss.item()
        return total_loss, loss_dict

class PPAGuidedContrastiveLoss(nn.Module):
    """PPA导向的对比学习损失"""

    def __init__(self, temperature=0.07, margin=0.2):
        super().__init__()
        self.temperature = temperature
        self.margin = margin  # 边际参数，用于控制正负样本的区分度

    def forward(self, code_embeddings, ppa_embeddings, group_ids, ppa_scores, design_types, is_seed):
        """
        计算PPA导向对比学习损失

        Args:
            code_embeddings: 代码嵌入 [batch_size, embedding_dim]
            ppa_embeddings: PPA指标嵌入 [batch_size, embedding_dim]
            group_ids: 功能组ID列表
            ppa_scores: PPA评分张量 [batch_size]
            design_types: 每个样本的设计类型列表
            is_seed: 是否为种子代码的布尔列表
        """
        # 归一化嵌入
        code_embeddings = F.normalize(code_embeddings, p=2, dim=1)
        ppa_embeddings = F.normalize(ppa_embeddings, p=2, dim=1)

        batch_size = code_embeddings.size(0)
        device = code_embeddings.device

        # 1. 代码-PPA匹配基础损失
        sim_matrix = torch.matmul(code_embeddings, ppa_embeddings.T) / self.temperature
        labels = torch.arange(batch_size, device=device)
        code_ppa_loss = F.cross_entropy(sim_matrix, labels)

        # 如果批次中没有足够的样本或分组信息不完整，只返回基础损失
        if batch_size <= 1 or None in group_ids:
            return code_ppa_loss, code_ppa_loss, torch.tensor(0.0, device=device)

        # 2. 计算组内变体对比损失

        # 建立组索引映射
        group_indices = {}
        for i, gid in enumerate(group_ids):
            if gid not in group_indices:
                group_indices[gid] = []
            group_indices[gid].append(i)

        # 计算变体对比损失
        variant_contrast_loss = torch.tensor(0.0, device=device)
        contrastive_count = 0

        for gid, indices in group_indices.items():
            if len(indices) < 2:  # 需要至少两个样本才能比较
                continue

            # 按设计类型分组
            design_type_groups = {}
            for idx in indices:
                dt = design_types[idx]
                if dt not in design_type_groups:
                    design_type_groups[dt] = []
                design_type_groups[dt].append(idx)

            # 对每种设计类型单独处理
            for dt, dt_indices in design_type_groups.items():
                if len(dt_indices) < 2:
                    continue

                # 按PPA评分排序，找出最佳和最差变体
                sorted_indices = sorted(dt_indices, key=lambda i: ppa_scores[i].item(), reverse=True)

                # 选择评分最高的k个作为正样本，最低的k个作为负样本
                k = min(2, len(sorted_indices) // 3 + 1)  # 动态确定k值

                positive_indices = sorted_indices[:k]
                negative_indices = sorted_indices[-k:] if len(sorted_indices) > k else []

                # 对每个样本，拉近与高分变体的距离，推远与低分变体的距离
                for idx in dt_indices:
                    emb = code_embeddings[idx]

                    # 计算与正样本的对比损失
                    for pos_idx in positive_indices:
                        if pos_idx == idx:
                            continue

                        pos_emb = code_embeddings[pos_idx]
                        pos_sim = F.cosine_similarity(emb.unsqueeze(0), pos_emb.unsqueeze(0))

                        # 相似度越高，损失越低
                        pos_loss = torch.clamp(1.0 - pos_sim, min=0.0)
                        variant_contrast_loss += pos_loss
                        contrastive_count += 1

                    # 计算与负样本的对比损失
                    for neg_idx in negative_indices:
                        if neg_idx == idx:
                            continue

                        neg_emb = code_embeddings[neg_idx]
                        neg_sim = F.cosine_similarity(emb.unsqueeze(0), neg_emb.unsqueeze(0))

                        # 相似度越低，损失越低 (使用margin防止过度惩罚)
                        neg_loss = torch.clamp(neg_sim - (1.0 - self.margin), min=0.0)
                        variant_contrast_loss += neg_loss
                        contrastive_count += 1

        # 如果没有可比较的样本对，直接返回基础损失
        if contrastive_count == 0:
            return code_ppa_loss, code_ppa_loss, torch.tensor(0.0, device=device)

        # 计算平均变体对比损失
        variant_contrast_loss = variant_contrast_loss / contrastive_count

        # 总损失是代码-PPA匹配损失和变体对比损失的加权和
        # 基础任务权重略高，确保代码和PPA的对应关系能够正确学习
        total_loss = 0.6 * code_ppa_loss + 0.4 * variant_contrast_loss

        return total_loss, code_ppa_loss, variant_contrast_loss
