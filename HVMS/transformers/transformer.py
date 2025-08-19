import re
import logging
from abc import ABC, abstractmethod


class BaseTransformer(ABC):
    """所有Verilog代码变换器的基类"""

    def __init__(self, agent, logger=None):
        """
        初始化变换器

        Args:
            agent: Claude Agent实例
            logger: 日志记录器
        """
        self.agent = agent
        self.logger = logger or logging.getLogger(self.__class__.__name__)

    @abstractmethod
    def get_prompt(self, code):
        """
        生成用于特定变换的提示

        Args:
            code: 原始Verilog代码

        Returns:
            str: 提示内容
        """
        pass

    @abstractmethod
    def is_applicable(self, code):
        """
        检查变换是否适用于给定代码

        Args:
            code: Verilog代码

        Returns:
            bool: 是否适用
        """
        pass

    def transform(self, code):
        """
        执行代码变换

        Args:
            code: 原始Verilog代码

        Returns:
            str: 变换后的代码
        """
        if not self.is_applicable(code):
            self.logger.info(f"{self.__class__.__name__} 不适用于当前代码")
            return code

        self.logger.info(f"开始执行 {self.__class__.__name__} 变换")
        transformed_code = self.agent.transform(code, self.__class__.__name__, self)

        if transformed_code == code:
            self.logger.info(f"{self.__class__.__name__} 变换未产生变化")
        else:
            self.logger.info(f"{self.__class__.__name__} 变换已完成")

        return transformed_code
