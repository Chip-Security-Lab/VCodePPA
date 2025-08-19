from .arch_transformers import FSMEncodingTransformer, InterfaceProtocolTransformer, ComputationUnitTransformer
from .logic_transformers import ControlFlowTransformer, OperatorRewriteTransformer, LogicLayerTransformer
from .timing_transformers import CriticalPathTransformer, RegisterRetimingTransformer, PipelineTransformer


class TransformerManager:
    """Verilog代码变换器管理器"""

    def __init__(self, agent, logger=None):
        """
        初始化变换器管理器

        Args:
            agent: Claude Agent实例
            logger: 日志记录器
        """
        # 初始化所有变换器
        self.transformers = {
            # 架构层变换器
            'fsm_encoding': FSMEncodingTransformer(agent, logger),
            'interface_protocol': InterfaceProtocolTransformer(agent, logger),
            'computation_unit': ComputationUnitTransformer(agent, logger),

            # 逻辑层变换器
            'control_flow': ControlFlowTransformer(agent, logger),
            'operator_rewrite': OperatorRewriteTransformer(agent, logger),
            'logic_layer': LogicLayerTransformer(agent, logger),

            # 时序层变换器
            'critical_path': CriticalPathTransformer(agent, logger),
            'register_timing': RegisterRetimingTransformer(agent, logger),
            'pipeline': PipelineTransformer(agent, logger)
        }

        self.logger = logger

    def get_available_transformations(self, code):
        """
        获取适用于给定代码的所有变换

        Args:
            code: Verilog代码

        Returns:
            list: 适用的变换名称列表
        """
        available = []
        for name, transformer in self.transformers.items():
            if transformer.is_applicable(code):
                available.append(name)

        if self.logger:
            self.logger.info(f"可用变换: {available}")

        return available

    def apply_transformation(self, code, transformation_name):
        """
        应用指定的变换到代码

        Args:
            code: Verilog代码
            transformation_name: 变换名称

        Returns:
            str: 变换后的代码
        """
        if transformation_name not in self.transformers:
            if self.logger:
                self.logger.error(f"未知的变换类型: {transformation_name}")
            raise ValueError(f"未知的变换类型: {transformation_name}")

        transformer = self.transformers[transformation_name]
        return transformer.transform(code)
