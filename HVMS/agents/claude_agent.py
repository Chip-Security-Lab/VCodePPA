import requests
import json
import time
import logging
import re
import os
from typing import Optional, Dict, Any


class ClaudeAgent:
    """使用Claude API进行Verilog代码变换的代理"""

    def __init__(self, api_key: str, model: str = "[额度]claude-3-7-sonnet",
                 timeout: int = 60, max_retries: int = 3, logger=None):
        """
        初始化Claude Agent

        Args:
            api_key: Claude API密钥
            model: 使用的Claude模型版本
            timeout: API调用超时时间(秒)
            max_retries: 失败重试次数
            logger: 日志记录器
        """
        self.api_key = api_key
        self.model = model
        self.timeout = timeout
        self.max_retries = max_retries
        self.api_url = "https://api.qingtian.shop/v1/messages"
        self.logger = logger or logging.getLogger(self.__class__.__name__)

    def transform(self, code: str, transformation_type: str, transformer) -> str:
        """
        使用Claude执行代码变换

        Args:
            code: 原始Verilog代码
            transformation_type: 变换类型
            transformer: 变换器实例，用于获取提示模板

        Returns:
            str: 变换后的代码
        """
        prompt = self._create_transformation_prompt(code, transformation_type, transformer)

        for attempt in range(self.max_retries):
            try:
                self.logger.info(f"尝试 {attempt + 1}/{self.max_retries} 执行 {transformation_type} 变换")

                response = self._call_claude_api(prompt)
                transformed_code = self._parse_response(response)

                if transformed_code and self._validate_syntax(transformed_code):
                    self.logger.info(f"{transformation_type} 变换成功")
                    return transformed_code

                self.logger.warning(f"变换生成的代码无效，重试...")

            except Exception as e:
                self.logger.error(f"API调用失败: {str(e)}")
                if attempt < self.max_retries - 1:
                    sleep_time = 2 * (attempt + 1)  # 指数退避
                    self.logger.info(f"等待 {sleep_time} 秒后重试...")
                    time.sleep(sleep_time)

        self.logger.warning(f"所有尝试都失败，返回原始代码")
        return code

    def _create_transformation_prompt(self, code: str, transformation_type: str, transformer) -> str:
        """
        创建用于Claude的变换提示

        Args:
            code: 原始Verilog代码
            transformation_type: 变换类型
            transformer: 变换器实例

        Returns:
            str: 格式化的提示
        """
        # 获取变换器提供的提示基础
        base_prompt = transformer.get_prompt(code)

        # 为Claude格式化提示
        # Claude通常对以人类风格表达的提示响应最佳
        system_prompt = """
        You are an expert FPGA/ASIC designer specializing in Verilog code optimization.
        Your task is to transform Verilog code according to specific requirements.
        Follow these rules:
        1. Only return the complete transformed Verilog code.
        2. Do not include explanations, analysis, or additional text.
        3. The transformed code must be functionally equivalent to the original.
        4. The code must be syntactically correct and follow Verilog standards.
        5. Use meaningful signal and variable names.
        6. Ensure proper timing and avoid race conditions.
        """

        return system_prompt + "\n\n" + base_prompt

    def _call_claude_api(self, prompt: str) -> Dict[str, Any]:
        """
        调用Claude API

        Args:
            prompt: 提示内容

        Returns:
            Dict: API响应
        """
        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        }

        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "max_tokens": 4000,
            "temperature": 0.6  # 平衡精确度和发散性
        }

        response = requests.post(
            self.api_url,
            headers=headers,
            json=payload,
            timeout=self.timeout
        )

        if response.status_code != 200:
            self.logger.error(f"API请求失败: {response.status_code} - {response.text}")
            raise Exception(f"API请求失败: {response.status_code}")

        return response.json()

    def _parse_response(self, response: Dict[str, Any]) -> Optional[str]:
        """
        从Claude API响应中提取Verilog代码

        Args:
            response: Claude API响应

        Returns:
            Optional[str]: 提取的Verilog代码，如果解析失败则返回None
        """
        try:
            # 获取Claude的回复内容
            content = response.get("content", [])
            if not content:
                self.logger.error("响应中未找到内容")
                return None

            text = ""
            for item in content:
                if item.get("type") == "text":
                    text += item.get("text", "")

            # 尝试从回复中提取Verilog代码
            # 首先尝试提取代码块
            code_pattern = r'```(?:verilog)?\s*([\s\S]*?)\s*```'
            code_matches = re.findall(code_pattern, text)

            if code_matches:
                return code_matches[0].strip()

            # 如果没有找到代码块，尝试提取模块定义
            module_pattern = r'(module\s+[\s\S]*?endmodule)'
            module_matches = re.findall(module_pattern, text)

            if module_matches:
                return module_matches[0].strip()

            # 如果仍然没有找到，可能整个响应就是代码
            if "module" in text and "endmodule" in text:
                return text.strip()

            self.logger.warning("无法从响应中提取Verilog代码")
            return None

        except Exception as e:
            self.logger.error(f"解析响应时出错: {str(e)}")
            return None

    def _validate_syntax(self, code: str) -> bool:
        """
        验证Verilog代码的语法正确性

        Args:
            code: Verilog代码

        Returns:
            bool: 代码是否语法正确
        """
        # 基本验证：检查模块定义和结束
        if not ("module" in code and "endmodule" in code):
            return False

        # 检查关键语法元素
        syntax_checks = [
            # 检查模块名称定义
            bool(re.search(r'module\s+\w+', code)),

            # 检查括号匹配
            code.count('(') == code.count(')'),
            code.count('[') == code.count(']'),
            code.count('{') == code.count('}'),

            # 检查语句结束符
            ';' in code,

            # 检查常见语法错误
            not "endmodule;" in code.replace("endmodule", "x")  # 防止误报
        ]

        # 如果存在iverilog，可以使用它进行更详细的语法检查
        if self._has_iverilog():
            return self._check_with_iverilog(code)

        # 否则使用基本检查
        return all(syntax_checks)

    def _has_iverilog(self) -> bool:
        """检查系统中是否安装了iverilog"""
        try:
            result = os.system("iverilog -h > nul 2>&1")
            return result == 0
        except:
            return False

    def _check_with_iverilog(self, code):
        """使用iverilog验证代码语法"""
        try:
            # 创建临时文件
            temp_file = "temp_verify.v"
            with open(temp_file, "w") as f:
                f.write(code)

            # 使用subprocess模块并打印详细信息
            import subprocess, shutil
            iverilog_path = shutil.which("iverilog")
            if not iverilog_path:
                self.logger.error("无法找到iverilog路径")
                return False

            self.logger.info(f"使用iverilog: {iverilog_path}")
            cmd = [iverilog_path, "-t", "null", temp_file]
            self.logger.info(f"执行命令: {' '.join(cmd)}")

            result = subprocess.run(cmd,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE)

            # 记录输出信息
            self.logger.info(f"命令返回码: {result.returncode}")
            self.logger.info(f"命令输出: {result.stdout.decode('utf-8', errors='ignore')}")
            self.logger.info(f"命令错误: {result.stderr.decode('utf-8', errors='ignore')}")

            # 删除临时文件
            import os
            if os.path.exists(temp_file):
                os.remove(temp_file)

            return result.returncode == 0

        except Exception as e:
            self.logger.error(f"iverilog验证出错: {str(e)}")
            return False
