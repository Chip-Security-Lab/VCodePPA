import random
import math
import logging
import os
from .nodes import MCTSNode
import re


class MCTSSearch:
    """基于蒙特卡洛树搜索的Verilog代码变异搜索"""

    def __init__(self, seed_code, seed_ppa, transformer_manager, vivado_tool,
                 verifier, max_depth=3, ppa_threshold=0.2, c_param=1.414, logger=None):
        """
        初始化MCTS搜索

        Args:
            seed_code: 种子Verilog代码
            seed_ppa: 种子代码的PPA指标
            transformer_manager: 变换器管理器
            vivado_tool: Vivado工具接口
            verifier: 功能验证工具
            max_depth: 最大搜索深度
            ppa_threshold: PPA变化阈值
            c_param: UCT公式中的探索参数
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
        self.logger = logger or logging.getLogger(self.__class__.__name__)

        # 添加变换计数器
        self.transform_count = 0

        # 创建根节点
        self.root = MCTSNode(state=seed_code, max_depth=max_depth)
        self.root.ppa_metrics = seed_ppa

        # 初始化未尝试的动作
        self.root.untried_actions = self._get_available_actions(seed_code)

        # 存储有价值的变异
        self.valuable_variants = []

    def search(self, target_count=10, max_iterations=1000):
        """
        执行MCTS搜索算法找到目标数量的有价值变异

        Args:
            target_count: 目标变异数量
            max_iterations: 最大迭代次数

        Returns:
            list: 有价值的变异列表，每个元素为(代码, PPA指标)元组
        """
        iteration = 0

        while len(self.valuable_variants) < target_count and iteration < max_iterations:
            # 记录当前迭代
            self.logger.info(
                f"MCTS迭代 {iteration + 1}/{max_iterations}, 已找到 {len(self.valuable_variants)}/{target_count} 个有价值变异")

            # 第1步：选择
            node = self._select(self.root)

            # 检查是否到达终端节点
            if node.is_terminal:
                # 评估终端节点
                reward = self._evaluate(node)
                self._backpropagate(node, reward)
                iteration += 1
                continue

            # 第2步：扩展
            child_node = self._expand(node)

            if child_node is None:
                # 无法扩展，回溯并继续
                iteration += 1
                continue

            # 第3步：模拟
            reward = self._simulate(child_node)

            # 第4步：反向传播
            self._backpropagate(child_node, reward)

            iteration += 1

        # 记录搜索结果
        self.logger.info(f"MCTS搜索完成，找到 {len(self.valuable_variants)}/{target_count} 个有价值变异")

        return self.valuable_variants

    def _select(self, node):
        """
        选择阶段 - 基于UCT公式选择最有前途的节点

        Args:
            node: 当前节点

        Returns:
            MCTSNode: 选择的节点
        """
        # 如果节点未完全扩展，则选择当前节点
        if not node.is_fully_expanded:
            return node

        # 如果节点是终端节点，则选择当前节点
        if node.is_terminal:
            return node

        # 使用UCT公式选择最佳子节点
        return self._select_best_child(node)

    def _select_best_child(self, node):
        """
        基于UCT公式选择最佳子节点

        Args:
            node: 当前节点

        Returns:
            MCTSNode: 最佳子节点
        """
        # 如果没有子节点，返回当前节点
        if not node.children:
            return node

        # 计算每个子节点的UCT值
        uct_values = []
        for child in node.children:
            if child.visits == 0:
                uct_values.append(float('inf'))
            else:
                exploitation = child.value / child.visits
                exploration = self.c_param * math.sqrt(2 * math.log(node.visits) / child.visits)
                uct_values.append(exploitation + exploration)

        # 选择UCT值最大的子节点
        best_child_index = uct_values.index(max(uct_values))

        # 递归选择
        return self._select(node.children[best_child_index])

    def _expand(self, node):
        """
        扩展阶段 - 创建新的子节点

        Args:
            node: 当前节点

        Returns:
            MCTSNode: 新创建的子节点
        """
        # 如果节点已经是终端节点，则不能扩展
        if node.is_terminal:
            return None

        # 如果没有未尝试的动作，则不能扩展
        if not node.untried_actions:
            # 检查是否有可用的动作
            available_actions = self._get_available_actions(node.state)

            if not available_actions:
                return None

            node.untried_actions = available_actions

        # 随机选择一个未尝试的动作
        action = random.choice(node.untried_actions)
        node.untried_actions.remove(action)

        # 应用变换，获取新状态
        try:
            self.logger.info(f"尝试应用变换: {action}")
            new_state = self._apply_transformation(node.state, action)

            # 检查变换是否产生了新的代码
            if new_state == node.state:
                self.logger.info(f"变换 {action} 未产生变化")
                return self._expand(node)  # 重试扩展

            # 验证功能等价性
            if not self._verify_functionality(node.state, new_state):
                self.logger.warning(f"变换 {action} 导致功能不等价")
                return self._expand(node)  # 重试扩展

            # 创建子节点
            child_node = node.add_child(new_state, action)

            # 获取PPA指标
            child_node.ppa_metrics = self._evaluate_ppa(new_state)

            return child_node

        except Exception as e:
            self.logger.error(f"扩展节点时出错: {str(e)}")
            return self._expand(node)  # 重试扩展

    def _simulate(self, node):
        """
        模拟阶段 - 从当前节点模拟到终止状态并评估奖励

        Args:
            node: 当前节点

        Returns:
            float: 模拟奖励
        """
        # 如果没有PPA指标，则计算
        if node.ppa_metrics is None:
            node.ppa_metrics = self._evaluate_ppa(node.state)

        # 计算PPA变化程度
        ppa_change = self._calculate_ppa_change(self.seed_ppa, node.ppa_metrics)

        # 如果PPA变化超过阈值，认为是有价值的变异
        if ppa_change > self.ppa_threshold:
            # 添加到有价值的变异列表
            variant_tuple = (node.state, node.ppa_metrics)

            # 检查是否已经存在
            variant_exists = False
            for existing_code, _ in self.valuable_variants:
                if existing_code == node.state:
                    variant_exists = True
                    break

            if not variant_exists:
                self.valuable_variants.append(variant_tuple)
                self.logger.info(f"找到有价值的变异，PPA变化: {ppa_change:.2f}")

            return 1.0  # 奖励值
        else:
            return 0.0  # 中性奖励

    def _extract_module_name(self, code):
        """
        从Verilog代码中提取模块名

        Args:
            code: Verilog代码

        Returns:
            str: 模块名
        """
        match = re.search(r'module\s+(\w+)', code)
        if match:
            return match.group(1)
        return "unknown_module"

    def _evaluate(self, node):
        """
        评估终端节点

        Args:
            node: 终端节点

        Returns:
            float: 评估值
        """
        # 如果已经有PPA指标，使用已有的指标
        if node.ppa_metrics is not None:
            ppa_change = self._calculate_ppa_change(self.seed_ppa, node.ppa_metrics)

            if ppa_change > self.ppa_threshold:
                # 添加到有价值的变异列表
                variant_tuple = (node.state, node.ppa_metrics)

                # 检查是否已经存在
                variant_exists = False
                for existing_code, _ in self.valuable_variants:
                    if existing_code == node.state:
                        variant_exists = True
                        break

                if not variant_exists:
                    self.valuable_variants.append(variant_tuple)
                    self.logger.info(f"找到有价值的变异，PPA变化: {ppa_change:.2f}")

                return 1.0  # 奖励值
            else:
                return 0.0  # 中性奖励
        else:
            # 获取PPA指标并评估
            node.ppa_metrics = self._evaluate_ppa(node.state)
            return self._simulate(node)

    def _backpropagate(self, node, reward):
        """
        反向传播阶段 - 更新节点统计信息

        Args:
            node: 当前节点
            reward: 奖励值
        """
        while node is not None:
            node.update(reward)
            node = node.parent

    def _get_available_actions(self, code):
        """
        获取适用于给定代码的所有变换动作

        Args:
            code: Verilog代码

        Returns:
            list: 可用变换动作列表
        """
        return self.transformer_manager.get_available_transformations(code)

    def _apply_transformation(self, code, action):
        """
        应用变换动作到代码上

        Args:
            code: Verilog代码
            action: 变换动作

        Returns:
            str: 变换后的代码
        """
        transformed_code = self.transformer_manager.apply_transformation(code, action)

        # 如果代码有变化，增加变换计数
        if transformed_code != code:
            self.transform_count += 1
            self.logger.info(f"变换计数增加到: {self.transform_count}")

        return transformed_code

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

    def _evaluate_ppa(self, code):
        """
        评估代码的PPA指标

        Args:
            code: Verilog代码

        Returns:
            dict: PPA指标
        """
        return self.vivado_tool.get_ppa_metrics(code)
