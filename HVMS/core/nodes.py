import math


class MCTSNode:
    """MCTS搜索树节点"""

    def __init__(self, state, parent=None, action=None, depth=0, max_depth=3):
        """
        初始化MCTS节点

        Args:
            state: 节点状态 (Verilog代码)
            parent: 父节点
            action: 从父节点到达此节点的变换动作
            depth: 搜索深度
            max_depth: 最大搜索深度
        """
        self.state = state  # Verilog代码
        self.parent = parent  # 父节点
        self.action = action  # 从父节点到达此节点的变换动作
        self.children = []  # 子节点
        self.visits = 0  # 访问次数
        self.value = 0  # 节点评估值
        self.depth = depth  # 搜索深度
        self.max_depth = max_depth  # 最大搜索深度
        self.untried_actions = []  # 未尝试的动作
        self.ppa_metrics = None  # 节点的PPA指标

    @property
    def is_fully_expanded(self):
        """判断节点是否已完全扩展"""
        return len(self.untried_actions) == 0

    @property
    def is_terminal(self):
        """判断节点是否为终端节点"""
        return self.depth >= self.max_depth  # 达到最大深度

    @property
    def uct_value(self, c_param=1.414):
        """
        计算节点的UCT值

        Args:
            c_param: UCT公式中的探索参数

        Returns:
            float: UCT值
        """
        if self.visits == 0:
            return float('inf')

        exploitation = self.value / self.visits

        if self.parent is None or self.parent.visits == 0:
            exploration = c_param
        else:
            exploration = c_param * math.sqrt(2 * math.log(self.parent.visits) / self.visits)

        return exploitation + exploration

    def add_child(self, state, action):
        """
        添加子节点

        Args:
            state: 子节点状态
            action: 到达子节点的动作

        Returns:
            MCTSNode: 新创建的子节点
        """
        child = MCTSNode(
            state=state,
            parent=self,
            action=action,
            depth=self.depth + 1,
            max_depth=self.max_depth  # 传递最大深度参数
        )

        self.children.append(child)

        if action in self.untried_actions:
            self.untried_actions.remove(action)

        return child

    def update(self, result):
        """
        更新节点统计信息

        Args:
            result: 模拟结果
        """
        self.visits += 1
        self.value += result

    def __str__(self):
        """字符串表示"""
        return f"MCTSNode(depth={self.depth}, visits={self.visits}, value={self.value:.2f}, actions={len(self.untried_actions)})"
