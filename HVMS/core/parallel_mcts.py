import os
import time
import random
import logging
import subprocess
import multiprocessing
from multiprocessing.pool import ThreadPool
from typing import List, Tuple, Dict, Any


class ParallelMCTSSearch:
    """并行多条路径的蒙特卡洛树搜索"""

    def __init__(self, seed_code, seed_ppa, transformer_manager, vivado_tool,
                 verifier, max_depth=3, ppa_threshold=0.2, c_param=1.414,
                 max_workers=4, paths_per_batch=8, logger=None):
        """
        初始化并行MCTS搜索

        Args:
            seed_code: 种子Verilog代码
            seed_ppa: 种子代码的PPA指标
            transformer_manager: 变换器管理器
            vivado_tool: Vivado工具接口
            verifier: 功能验证工具
            max_depth: 最大搜索深度
            ppa_threshold: PPA变化阈值
            c_param: UCT公式中的探索参数
            max_workers: 最大并行工作线程数
            paths_per_batch: 每批次探索的路径数
            logger: 日志记录器
        """
        self.seed_code = seed_code
        self.seed_ppa = seed_ppa
        self.transformer_manager = transformer_manager
        self.vivado_tool = vivado_tool
        self.verifier = verifier
        self.max_depth = max_depth
        self.ppa_threshold = ppa_threshold
        self.c_param = c_param
        self.max_workers = max_workers
        self.paths_per_batch = paths_per_batch
        self.logger = logger or logging.getLogger(self.__class__.__name__)

        # 存储有价值的变异
        self.valuable_variants = []

        # 不在初始化时创建进程池，而是在需要时创建并在使用后关闭

        # 创建变体候选队列
        self.candidate_queue = []

    def search(self, target_count=10, max_iterations=1000):
        """
        执行并行MCTS搜索

        Args:
            target_count: 目标变异数量
            max_iterations: 最大迭代次数

        Returns:
            list: 有价值的变异列表
        """
        self.logger.info(f"开始并行MCTS搜索 - 当前参数: "
                         f"max_depth={self.max_depth}, "
                         f"ppa_threshold={self.ppa_threshold}, "
                         f"max_workers={self.max_workers}, "
                         f"paths_per_batch={self.paths_per_batch},")

        iteration = 0
        batch_size = min(self.paths_per_batch, max_iterations)

        while len(self.valuable_variants) < target_count and iteration < max_iterations:
            self.logger.info(f"MCTS迭代批次 {iteration // batch_size + 1}, "
                             f"已找到 {len(self.valuable_variants)}/{target_count} 个有价值变异")

            # 1. 并行探索多条路径
            paths = self._explore_multiple_paths(batch_size)

            # 2. 批量评估候选变体
            candidates = self._evaluate_candidates(paths)

            # 3. 更新有价值的变异
            self._update_valuable_variants(candidates)

            iteration += batch_size

            if len(self.valuable_variants) >= target_count:
                break

        self.logger.info(f"MCTS搜索完成，找到 {len(self.valuable_variants)}/{target_count} 个有价值变异")
        return self.valuable_variants

    def _explore_multiple_paths(self, num_paths):
        """
        并行探索多条搜索路径

        Args:
            num_paths: 要探索的路径数量

        Returns:
            list: 探索路径列表，每个元素为(最终代码, 变换序列)
        """
        paths = []

        # 使用线程池而不是进程池
        with ThreadPool(processes=self.max_workers) as pool:
            # 启动多个探索任务 - 注意这里不应传入额外参数
            search_tasks = []
            for _ in range(num_paths):
                task = pool.apply_async(self._explore_single_path)  # 确保这里不传递额外参数
                search_tasks.append(task)

            # 收集结果
            for task in search_tasks:
                try:
                    path = task.get(timeout=600)  # 10分钟超时
                    if path:
                        paths.append(path)
                except Exception as e:
                    self.logger.error(f"路径探索失败: {str(e)}")

        return paths

    def _explore_single_path(self):
        """
        探索单条路径到指定深度

        Returns:
            tuple: (最终代码, 变换序列, 变换深度)
        """
        import random

        # 根据指定概率随机选择最大搜索深度
        depth_choices = [1, 2, 3]
        depth_weights = [0.3, 0.5, 0.2]  # 30%, 50%, 20%的概率
        path_max_depth = random.choices(depth_choices, weights=depth_weights, k=1)[0]

        self.logger.info(f"为此路径随机选择最大深度: {path_max_depth}")

        current_code = self.seed_code
        transformations = []
        current_depth = 0
        transform_attempt = 0

        while current_depth < path_max_depth:  # 使用随机生成的最大深度
            # 显示当前深度
            self.logger.info(f"当前搜索深度: {current_depth}/{path_max_depth} 跳")

            # 获取可用变换
            available_actions = self._get_available_actions(current_code)
            if not available_actions:
                self.logger.info(f"没有更多可用变换，搜索停止于第 {current_depth} 跳")
                break

            # 随机选择一个变换
            action = random.choice(available_actions)

            try:
                # 记录变换尝试次数
                transform_attempt += 1

                # 应用变换
                self.logger.info(f"尝试第 {current_depth + 1} 跳变换: {action}")
                new_code = self._apply_transformation(current_code, action)

                # 跳过未变化的代码
                if new_code == current_code:
                    self.logger.info(f"变换未产生代码变化，跳过")
                    continue

                # 验证功能等价性
                if not self._verify_functionality(current_code, new_code, transform_attempt):
                    self.logger.info(f"功能等价性验证失败，跳过此变换")
                    continue

                # 更新当前状态
                current_code = new_code
                transformations.append(action)
                current_depth += 1
                self.logger.info(f"成功完成第 {current_depth} 跳变换: {action}")

            except Exception as e:
                self.logger.error(f"变换应用失败: {str(e)}")
                continue

        self.logger.info(f"路径探索完成，总共完成 {current_depth}/{path_max_depth} 跳变换")
        return (current_code, transformations, transform_attempt)

    def _evaluate_candidates(self, paths):
        """
        批量评估候选变体的PPA指标

        Args:
            paths: 路径列表，每个元素为(代码, 变换序列, 变换深度)

        Returns:
            list: 评估后的候选变体列表，每个元素为(代码, PPA指标, 变换序列, 变换深度)
        """
        candidates = []

        # 过滤重复代码
        unique_paths = []
        unique_codes = set()

        for code, transforms, transform_depth in paths:
            if code not in unique_codes and code != self.seed_code:
                unique_codes.add(code)
                unique_paths.append((code, transforms, transform_depth))

        # 如果没有有效路径，直接返回
        if not unique_paths:
            return []

        # 为了减少Vivado启动次数，逐个评估变体
        for i, (code, transforms, transform_depth) in enumerate(unique_paths):
            # 对于每个变体单独评估PPA
            try:
                self.logger.info(f"评估变体 {i + 1}/{len(unique_paths)}, 变换序列: {transforms}")
                # 使用现有vivado工具评估PPA
                ppa_metrics = self.vivado_tool.get_ppa_metrics(code)
                if ppa_metrics:
                    candidates.append((code, ppa_metrics, transforms, transform_depth))
            except Exception as e:
                self.logger.error(f"评估变体 {i + 1} 失败: {str(e)}")

        return candidates

    def _update_valuable_variants(self, candidates):
        """
        更新有价值的变异列表

        Args:
            candidates: 候选变体列表，每个元素为(代码, PPA指标, 变换序列, 变换深度)
        """
        for code, ppa_metrics, transforms, transform_depth in candidates:
            # 计算PPA变化程度
            ppa_change = self._calculate_ppa_change(self.seed_ppa, ppa_metrics)

            # 如果PPA变化超过阈值，认为是有价值的变异
            if ppa_change > self.ppa_threshold:
                # 检查是否已存在
                variant_exists = False
                for existing_code, _ in self.valuable_variants:
                    if existing_code == code:
                        variant_exists = True
                        break

                if not variant_exists:
                    self.valuable_variants.append((code, ppa_metrics))
                    self.logger.info(
                        f"找到有价值的变异，PPA变化: {ppa_change:.2f}，变换序列: {transforms}，变换深度: {transform_depth}")

    def _get_available_actions(self, code):
        """获取适用于给定代码的所有变换动作"""
        return self.transformer_manager.get_available_transformations(code)

    def _apply_transformation(self, code, action):
        """应用变换动作到代码上"""
        return self.transformer_manager.apply_transformation(code, action)

    def _verify_functionality(self, original_code, transformed_code, transform_count):
        """
        验证变换前后代码的功能等价性

        Args:
            original_code: 原始代码
            transformed_code: 变换后的代码
            transform_count: 变换计数

        Returns:
            bool: 是否功能等价
        """
        return self.verifier.verify_equivalence(
            original_code,
            transformed_code,
            transform_count=transform_count
        )

    def _calculate_ppa_change(self, base_ppa, current_ppa):
        """
        计算PPA变化程度

        Args:
            base_ppa: 基准PPA指标
            current_ppa: 当前PPA指标

        Returns:
            float: PPA变化程度 [0.0-1.0]
        """
        # 如果PPA指标不完整，返回0
        if not base_ppa or not current_ppa:
            return 0.0

        # 计算面积变化
        area_metrics = ['lut', 'ff', 'io', 'cell_count']  # 将utilization替换为cell_count
        area_changes = []

        for metric in area_metrics:
            if base_ppa.get(metric, 0) == 0:
                continue

            change = abs(current_ppa.get(metric, 0) - base_ppa.get(metric, 0)) / base_ppa.get(metric, 1)
            area_changes.append(min(change, 1.0))  # 限制最大变化为100%

        # 计算性能变化
        perf_metrics = ['max_freq', 'critical_path_delay']
        perf_changes = []

        for metric in perf_metrics:
            if base_ppa.get(metric, 0) == 0:
                continue

            change = abs(current_ppa.get(metric, 0) - base_ppa.get(metric, 0)) / base_ppa.get(metric, 1)
            perf_changes.append(min(change, 1.0))  # 限制最大变化为100%

        # 计算功耗变化 - 只考虑总功耗
        power_metrics = ['total_power']
        power_changes = []

        for metric in power_metrics:
            if base_ppa.get(metric, 0) == 0:
                continue

            change = abs(current_ppa.get(metric, 0) - base_ppa.get(metric, 0)) / base_ppa.get(metric, 1)
            power_changes.append(min(change, 1.0))  # 限制最大变化为100%

        # 计算总体变化
        changes = []

        if area_changes:
            changes.append(sum(area_changes) / len(area_changes))

        if perf_changes:
            changes.append(sum(perf_changes) / len(perf_changes))

        if power_changes:
            changes.append(sum(power_changes) / len(power_changes))

        # 返回总体变化
        if changes:
            return sum(changes) / len(changes)
        else:
            return 0.0

