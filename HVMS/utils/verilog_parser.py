import re
import os


class VerilogParser:
    """Verilog代码解析器"""

    @staticmethod
    def extract_module_name(code):
        """
        从Verilog代码中提取模块名称

        Args:
            code (str): Verilog代码

        Returns:
            str: 模块名称
        """
        pattern = r'module\s+(\w+)'
        match = re.search(pattern, code)
        if match:
            return match.group(1)
        return None

    @staticmethod
    def extract_ports(code):
        """
        从Verilog代码中提取端口列表

        Args:
            code (str): Verilog代码

        Returns:
            list: 端口列表
        """
        # 匹配模块声明中的端口列表
        pattern = r'module\s+\w+\s*\(([\s\S]*?)\);'
        match = re.search(pattern, code)

        if not match:
            return []

        port_text = match.group(1)
        # 移除注释
        port_text = re.sub(r'//.*?\n', '\n', port_text)
        port_text = re.sub(r'/\*[\s\S]*?\*/', '', port_text)

        # 分割端口
        ports = [p.strip() for p in port_text.split(',')]
        return [p for p in ports if p]

    @staticmethod
    def has_fsm(code):
        """
        检测代码是否包含有限状态机

        Args:
            code (str): Verilog代码

        Returns:
            bool: 是否包含FSM
        """
        # 检查状态寄存器定义
        has_state_reg = bool(re.search(r'reg\s+\[\s*\d+\s*:\s*\d+\s*\]\s+\w+_state', code))
        has_state_param = bool(re.search(r'parameter\s+\w+_STATE', code))
        # 检查case语句，常用于状态转换
        has_case_statement = "case" in code and "endcase" in code

        return (has_state_reg or has_state_param) and has_case_statement

    @staticmethod
    def has_arithmetic_operations(code):
        """
        检测代码是否包含算术运算

        Args:
            code (str): Verilog代码

        Returns:
            bool: 是否包含算术运算
        """
        # 检查常见的算术运算符
        patterns = [
            r'[^<>!=]=\s*[\w\s\[\]]+\s*\+\s*[\w\s\[\]]+',  # 加法
            r'[^<>!=]=\s*[\w\s\[\]]+\s*-\s*[\w\s\[\]]+',  # 减法
            r'[^<>!=]=\s*[\w\s\[\]]+\s*\*\s*[\w\s\[\]]+',  # 乘法
            r'[^<>!=]=\s*[\w\s\[\]]+\s*/\s*[\w\s\[\]]+',  # 除法
        ]

        return any(bool(re.search(pattern, code)) for pattern in patterns)

    @staticmethod
    def extract_parameters(code):
        """
        从Verilog代码中提取参数定义

        Args:
            code (str): Verilog代码

        Returns:
            dict: 参数名称和值的字典
        """
        pattern = r'parameter\s+(\w+)\s*=\s*([^;]+);'
        matches = re.finditer(pattern, code)

        parameters = {}
        for match in matches:
            name = match.group(1)
            value = match.group(2).strip()
            parameters[name] = value

        return parameters

    @staticmethod
    def scan_directory(directory):
        """
        扫描目录中的所有.v和.sv文件，并按文件名中的数字排序

        Args:
            directory (str): 目录路径

        Returns:
            list: 按序号排序的文件路径列表
        """
        import re
        verilog_files = []

        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(('.v', '.sv')):
                    verilog_files.append(os.path.join(root, file))

        # 定义一个函数来提取文件名中的数字
        def extract_number(file_path):
            filename = os.path.basename(file_path)
            # 尝试从文件名开头提取数字
            match = re.search(r'^(\d+)[.\s]', filename)
            if match:
                return int(match.group(1))
            return float('inf')  # 如果没有数字，放到最后

        # 按文件名中的数字排序
        return sorted(verilog_files, key=extract_number)

    @staticmethod
    def read_file(file_path):
        """
        读取Verilog文件

        Args:
            file_path (str): 文件路径

        Returns:
            str: 文件内容
        """
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            return f.read()

    @staticmethod
    def write_file(file_path, content):
        """
        写入Verilog文件

        Args:
            file_path (str): 文件路径
            content (str): 文件内容
        """
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
