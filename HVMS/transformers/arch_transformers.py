import re
from .transformer import BaseTransformer


class FSMEncodingTransformer(BaseTransformer):
    """有限状态机编码变换器"""

    def is_applicable(self, code):
        """检查代码是否包含FSM"""
        # 简单检测：寻找状态定义和状态切换模式
        has_state_reg = bool(re.search(r'reg\s+\[\s*\d+\s*:\s*\d+\s*\]\s+\w+_state', code))
        has_state_param = bool(re.search(r'parameter\s+\w+_STATE', code))
        has_case_statement = "case" in code and "endcase" in code

        return (has_state_reg or has_state_param) and has_case_statement

    def get_prompt(self, code):
        """为FSM编码变换生成提示"""
        # 分析当前FSM编码类型
        current_encoding = self._detect_encoding_type(code)
        target_encoding = self._select_target_encoding(current_encoding)

        return f"""
        你是一个专业的Verilog代码优化专家。请对下面的Verilog代码中的有限状态机(FSM)进行编码变换，
        将原始的{current_encoding}编码方式修改为{target_encoding}编码方式。

        请确保：
        1. 变换后的代码功能与原代码完全一致
        2. 只修改状态编码方式，保持模块接口和其他功能不变
        3. 优化后的代码应该使用{target_encoding}编码
        4. 确保所有状态转换逻辑正确转换

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的变换后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _detect_encoding_type(self, code):
        """检测FSM的当前编码类型"""
        # 检查是否使用独热编码
        onehot_pattern = re.search(r'parameter\s+\w+\s*=\s*\d+\'b(?:0*10*)+', code)
        if onehot_pattern:
            return "独热(one-hot)"

        # 检查是否使用二进制编码
        binary_values = re.findall(r'parameter\s+\w+\s*=\s*(\d+)\'b([01]+)', code)
        if binary_values:
            # 检查位宽和状态数量，判断是否为二进制编码
            return "二进制(binary)"

        # 检查是否使用格雷码
        # 这需要更复杂的分析...

        return "未知"

    def _select_target_encoding(self, current_encoding):
        """根据当前编码选择目标编码"""
        import random  # 添加random模块导入

        # 扩展编码选项列表
        encoding_options = [
            "独热(one-hot)",
            "二进制(binary)",
            "格雷码(gray-code)",
            "约翰逊(Johnson)",
            "单冷(One-Cold)",
            "状态表(State Table)",
            "混合编码(Hybrid)"
        ]

        # 如果当前编码在选项中，则将其移除以避免选择相同的编码
        if current_encoding in encoding_options:
            encoding_options.remove(current_encoding)

        # 如果没有可用选项，返回默认编码
        if not encoding_options:
            return "独热(one-hot)"

        # 随机选择一个编码选项
        return random.choice(encoding_options)

class InterfaceProtocolTransformer(BaseTransformer):
    """接口协议变换器"""

    def is_applicable(self, code):
        """检查代码是否包含可变换的接口协议"""
        try:
            # 移除注释，避免误判
            code_no_comments = re.sub(r'//.*?\n', '\n', code)
            code_no_comments = re.sub(r'/\*[\s\S]*?\*/', '', code_no_comments)

            # 检查是否是模块定义
            if not re.search(r'module\s+\w+', code_no_comments):
                self.logger.info("非模块定义代码，不适用接口变换")
                return False

            # 检查是否有端口定义
            if not re.search(r'module\s+\w+\s*\([^)]*\)', code_no_comments):
                self.logger.info("未发现端口定义，不适用接口变换")
                return False

            # 接口协议特征检测
            features = {
                # 握手机制检测（更精确的模式）
                'valid_ready_handshake': bool(re.search(r'\b(valid|ready)\b', code_no_comments)) and
                                         bool(
                                             re.search(r'\bvalid\b.*\bready\b|\bready\b.*\bvalid\b', code_no_comments)),
                'req_ack_handshake': bool(re.search(r'\b(req|request|ack|acknowledge)\b', code_no_comments)) and
                                     bool(re.search(r'\breq\b.*\back\b|\back\b.*\breq\b|\brequest\b.*\backnowledge\b',
                                                    code_no_comments)),

                # 总线协议检测
                'axi': bool(re.search(r'\b(axi|axi4|axi_lite|axil)\b', code_no_comments.lower())),
                'axi_stream': bool(re.search(r'\b(axis|axi_stream|tvalid|tready|tdata)\b', code_no_comments.lower())),
                'wishbone': bool(re.search(r'\b(wishbone|wb_)\b', code_no_comments.lower())) or
                            bool(re.search(r'\bwb_(adr|dat|sel|cyc|stb|ack|we)\b', code_no_comments.lower())),
                'avalon': bool(re.search(r'\b(avalon|avmm|avst)\b', code_no_comments.lower())),
                'apb': bool(re.search(r'\b(apb|psel|penable|pready|pwrite)\b', code_no_comments.lower())),

                # 数据宽度检测
                'data_width_4': bool(re.search(r'\[\s*3\s*:\s*0\s*\]', code_no_comments)),
                'data_width_8': bool(re.search(r'\[\s*7\s*:\s*0\s*\]', code_no_comments)),
                'data_width_16': bool(re.search(r'\[\s*15\s*:\s*0\s*\]', code_no_comments)),
                'data_width_32': bool(re.search(r'\[\s*31\s*:\s*0\s*\]', code_no_comments)),

                # 通道特性检测
                'multi_channel': len(re.findall(r'\b(channel|ch)\s*\d+\b', code_no_comments)) > 1 or
                                 bool(re.search(r'\[\s*\d+\s*:\s*0\s*\]\s*channel', code_no_comments)),

                # 突发传输检测
                'burst_support': bool(re.search(r'\b(burst|len|size|length|awlen|arlen)\b', code_no_comments.lower())),

                # 时序特性检测
                'pipeline': bool(re.search(r'\b(pipeline|pipe|stage)\b', code_no_comments.lower())),
                'single_cycle': bool(re.search(r'always\s*@\s*\([^)]*posedge[^)]*\)', code_no_comments)) and
                                not bool(re.search(r'\b(pipeline|pipe|stage)\b', code_no_comments.lower())),

                # 流控制检测
                'flow_control': bool(
                    re.search(r'\b(backpressure|back_pressure|flow_control|throttle)\b', code_no_comments.lower()))
            }

            # 判断是否适用于协议变换
            has_protocol_feature = any(features.values())

            # 接口信号数量检查 - 确保有足够的接口信号才考虑变换
            port_match = re.search(r'module\s+\w+\s*\(([\s\S]*?)\);', code_no_comments)
            if port_match:
                port_text = port_match.group(1)
                port_count = len([p for p in port_text.split(',') if p.strip()])
                # 如果端口数量太少（<3），可能不是复杂接口
                if port_count < 3:
                    self.logger.info(f"接口端口数量较少 ({port_count}), 可能不适用于复杂接口变换")
                    # 但如果明确检测到接口协议特征，仍然允许变换
                    return has_protocol_feature

            # 最终判断是否适用变换
            if has_protocol_feature:
                # 记录检测到的特征，便于后续选择变换类型
                self.detected_features = {k: v for k, v in features.items() if v}
                self.logger.info(f"检测到接口特征: {', '.join(self.detected_features.keys())}")
                return True
            else:
                self.logger.info("未检测到明确的接口协议特征")
                # 如果没有明确特征但有输入输出信号，仍可以考虑基本接口变换
                has_input = bool(re.search(r'\binput\b', code_no_comments))
                has_output = bool(re.search(r'\boutput\b', code_no_comments))
                return has_input and has_output

        except Exception as e:
            self.logger.error(f"检查接口适用性时出错: {str(e)}")
            # 出错时保守返回False
            return False

    def get_prompt(self, code):
        """为接口协议变换生成提示"""
        # 检测当前协议类型和特征
        current_protocol = self._detect_protocol(code)
        target_protocol = self._select_target_protocol(current_protocol, code)

        return f"""
        你是一个专业的Verilog硬件接口设计专家。请将下面的Verilog代码中的{current_protocol['name']}接口协议
        转换为{target_protocol['name']}接口协议。转换的具体要求是：{target_protocol['description']}

        请确保：
        1. 保持模块的核心功能不变
        2. 仅修改接口部分，包括端口定义和接口逻辑
        3. 正确实现{target_protocol['name']}的时序和握手机制
        4. 如果需要添加新的内部信号或寄存器来支持协议转换，请合理命名
        5. 保持代码可读性和清晰度

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的转换后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _detect_protocol(self, code):
        """检测当前使用的接口协议和特征"""
        protocol = {"name": "标准接口", "features": []}

        # 检测总线类型
        if "axi" in code.lower():
            if "axi_stream" in code.lower() or "axis_" in code.lower():
                protocol["name"] = "AXI-Stream"
                protocol["type"] = "stream"
            elif "axi4" in code.lower():
                protocol["name"] = "AXI4"
                protocol["type"] = "memory"
            else:
                protocol["name"] = "AXI"
                protocol["type"] = "memory"
        elif "wb_" in code or "wishbone" in code.lower():
            protocol["name"] = "Wishbone"
            protocol["type"] = "memory"
        elif "avalon" in code.lower():
            if "avalon_st" in code.lower() or "avst" in code.lower():
                protocol["name"] = "Avalon-ST"
                protocol["type"] = "stream"
            else:
                protocol["name"] = "Avalon-MM"
                protocol["type"] = "memory"
        elif "valid" in code and "ready" in code:
            protocol["name"] = "Valid-Ready握手"
            protocol["type"] = "handshake"
        elif "req" in code and "ack" in code:
            protocol["name"] = "请求-应答握手"
            protocol["type"] = "handshake"

        # 检测数据宽度
        if bool(re.search(r'\[\s*7\s*:\s*0\s*\]', code)):
            protocol["features"].append("8位数据宽度")
        elif bool(re.search(r'\[\s*15\s*:\s*0\s*\]', code)):
            protocol["features"].append("16位数据宽度")
        elif bool(re.search(r'\[\s*31\s*:\s*0\s*\]', code)):
            protocol["features"].append("32位数据宽度")
        elif bool(re.search(r'\[\s*63\s*:\s*0\s*\]', code)):
            protocol["features"].append("64位数据宽度")

        # 检测通道特性
        if len(re.findall(r'channel\s*\d+', code)) > 1 or len(re.findall(r'ch\s*\d+', code)) > 1:
            protocol["features"].append("多通道")

        # 检测突发传输
        if "burst" in code.lower() or ("len" in code.lower() and "size" in code.lower()):
            protocol["features"].append("支持突发传输")

        # 检测流控制
        if "backpressure" in code.lower() or "back_pressure" in code.lower():
            protocol["features"].append("带背压流控")

        # 检测时序特性
        if "pipeline" in code.lower() or "pipe" in code.lower():
            protocol["features"].append("流水线接口")

        return protocol

    def _select_target_protocol(self, current_protocol, code):
        """选择目标协议"""
        import random

        # 定义转换类型及其描述
        transformations = [
            # 总线标准转换
            {
                "from": "AXI", "to": "Wishbone",
                "name": "Wishbone总线",
                "description": "将AXI总线接口转换为Wishbone总线接口，保留相同的功能特性"
            },
            {
                "from": "Wishbone", "to": "AXI",
                "name": "AXI总线",
                "description": "将Wishbone总线接口转换为AXI总线接口，保留相同的功能特性"
            },
            {
                "from": "AXI", "to": "Avalon-MM",
                "name": "Avalon-MM总线",
                "description": "将AXI总线接口转换为Avalon-MM总线接口，保留相同的功能特性"
            },
            {
                "from": "Avalon-MM", "to": "AXI",
                "name": "AXI总线",
                "description": "将Avalon-MM总线接口转换为AXI总线接口，保留相同的功能特性"
            },

            # 握手协议转换
            {
                "from": "Valid-Ready握手", "to": "请求-应答握手",
                "name": "请求-应答(Req-Ack)握手",
                "description": "将Valid-Ready握手协议转换为请求-应答(Req-Ack)握手协议，保持相同的数据传输功能"
            },
            {
                "from": "请求-应答握手", "to": "Valid-Ready握手",
                "name": "Valid-Ready握手",
                "description": "将请求-应答(Req-Ack)握手协议转换为Valid-Ready握手协议，保持相同的数据传输功能"
            },

            # 数据宽度变换
            {
                "feature": "8位数据宽度", "to": "32位数据宽度",
                "name": "32位数据接口",
                "description": "将8位数据宽度扩展为32位数据宽度，通过合并多个8位数据或填充方式实现"
            },
            {
                "feature": "32位数据宽度", "to": "8位数据宽度",
                "name": "8位数据接口",
                "description": "将32位数据宽度分解为8位数据宽度，通过分段传输的方式实现"
            },
            {
                "feature": "16位数据宽度", "to": "32位数据宽度",
                "name": "32位数据接口",
                "description": "将16位数据宽度扩展为32位数据宽度，通过合并多个16位数据或填充方式实现"
            },
            {
                "feature": "32位数据宽度", "to": "16位数据宽度",
                "name": "16位数据接口",
                "description": "将32位数据宽度分解为16位数据宽度，通过分段传输的方式实现"
            },

            # 通道复用
            {
                "feature": "多通道", "to": "时分复用",
                "name": "时分复用单通道",
                "description": "将多个并行通道转换为一个时分复用的单通道，添加通道选择逻辑"
            },
            {
                "feature": "时分复用", "to": "多通道",
                "name": "多并行通道",
                "description": "将时分复用单通道转换为多个并行通道，分离各个通道的数据流"
            },

            # 流控制变换
            {
                "feature": "无流控", "to": "简单握手",
                "name": "带简单握手的接口",
                "description": "为接口添加简单的握手机制，确保数据传输的可靠性"
            },
            {
                "feature": "简单握手", "to": "带背压流控",
                "name": "带背压流控的接口",
                "description": "升级简单握手为带背压的流控机制，允许接收方控制发送速率"
            },

            # 时序变换
            {
                "feature": "单周期接口", "to": "多周期接口",
                "name": "多周期接口",
                "description": "将单周期接口改为多周期接口，增加握手机制来协调多周期传输"
            },
            {
                "feature": "流水线接口", "to": "非流水线接口",
                "name": "非流水线接口",
                "description": "将流水线接口改为非流水线接口，简化控制逻辑但可能降低吞吐量"
            },
            {
                "feature": "非流水线接口", "to": "流水线接口",
                "name": "流水线接口",
                "description": "将非流水线接口改为流水线接口，通过添加流水线寄存器提高吞吐量"
            },

            # 突发支持
            {
                "feature": "单次传输", "to": "简单突发",
                "name": "支持简单突发的接口",
                "description": "为接口添加简单的突发传输支持，能够连续传输多个数据"
            },
            {
                "feature": "支持突发传输", "to": "单次传输",
                "name": "单次传输接口",
                "description": "简化接口移除突发传输功能，每次只传输一个数据单元"
            }
        ]

        # 筛选适用的转换
        applicable_transforms = []

        # 首先尝试基于当前协议名称匹配
        for transform in transformations:
            if "from" in transform and transform["from"] == current_protocol["name"]:
                applicable_transforms.append(transform)

        # 如果没有找到基于协议名称的匹配，尝试基于特征匹配
        if not applicable_transforms:
            for feature in current_protocol["features"]:
                for transform in transformations:
                    if "feature" in transform and transform["feature"] == feature:
                        applicable_transforms.append(transform)

        # 检查特定的接口类型没有找到对应的转换
        if not applicable_transforms:
            # 为标准接口添加一些默认转换
            if current_protocol["name"] == "标准接口":
                # 如果没有明确的握手机制
                if "valid" not in code and "ready" not in code and "req" not in code and "ack" not in code:
                    applicable_transforms.append({
                        "name": "Valid-Ready握手",
                        "description": "为标准接口添加Valid-Ready握手机制，提高接口可靠性"
                    })
                # 如果看起来是数据接口但没有明确宽度
                elif not any(f for f in current_protocol["features"] if "位数据宽度" in f):
                    width = random.choice(["8", "16", "32"])
                    applicable_transforms.append({
                        "name": f"{width}位数据接口",
                        "description": f"将接口标准化为{width}位数据宽度"
                    })

        # 如果仍然没有适用的转换，使用一些通用转换
        if not applicable_transforms:
            applicable_transforms = [
                {
                    "name": "Valid-Ready握手",
                    "description": "添加标准Valid-Ready握手机制，提高接口可靠性"
                },
                {
                    "name": "Wishbone总线",
                    "description": "将当前接口转换为标准Wishbone总线接口"
                },
                {
                    "name": "AXI-Stream接口",
                    "description": "将当前接口转换为AXI-Stream流接口"
                }
            ]

        # 随机选择一个适用的转换
        return random.choice(applicable_transforms)


class ComputationUnitTransformer(BaseTransformer):
    """运算单元替换变换器"""

    def is_applicable(self, code):
        """检查代码是否包含可替换的运算单元"""
        # 检测代码中的运算模式
        has_multiplier = "*" in code or "mult" in code.lower()
        has_divider = "/" in code or "div" in code.lower()
        has_adder = "+" in code or "add" in code.lower()
        has_complex_function = "sin" in code.lower() or "cos" in code.lower() or "log" in code.lower()

        return has_multiplier or has_divider or has_adder or has_complex_function

    def get_prompt(self, code):
        """为运算单元替换生成提示"""
        # 检测当前运算类型
        operation_type = self._detect_operation_type(code)
        alternative_impl = self._select_alternative_implementation(operation_type)

        return f"""
        你是一个专业的Verilog硬件优化专家。请对下面的Verilog代码中的{operation_type}运算单元
        进行替换，改用{alternative_impl}算法实现。

        请确保：
        1. 保持模块的功能行为不变
        2. 使用{alternative_impl}算法重新实现{operation_type}功能
        3. 合理命名新增的信号和寄存器
        4. 代码时序正确，无竞态冒险

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的优化后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _detect_operation_type(self, code):
        """检测代码中的主要运算类型"""
        if "*" in code or "mult" in code.lower():
            return "乘法器"
        elif "/" in code or "div" in code.lower():
            return "除法器"
        elif "+" in code or "add" in code.lower():
            return "加法器"
        elif "sin" in code.lower() or "cos" in code.lower():
            return "三角函数"
        else:
            return "算术运算"

    def _select_alternative_implementation(self, operation_type):
        """选择替代实现方案"""
        import random  # 导入random模块以支持随机选择

        implementations = {
            "乘法器": [
                "Booth乘法器",
                "Wallace树乘法器",
                "移位累加乘法器",
                "基拉斯基乘法器",
                "递归Karatsuba乘法",
                "Baugh-Wooley乘法器",
                "Dadda乘法器",
                "带符号乘法优化实现"
            ],
            "除法器": [
                "不恢复余数除法器",
                "SRT除法器",
                "牛顿-拉弗森迭代",
                "Goldschmidt除法器",
                "二进制长除法",
                "查找表辅助除法器",
                "移位减法除法器"
            ],
            "加法器": [
                "先行进位加法器",
                "带状进位加法器",
                "并行前缀加法器",
                "Kogge-Stone加法器",
                "Brent-Kung加法器",
                "Han-Carlson加法器",
                "曼彻斯特进位链加法器",
                "跳跃进位加法器"
            ],
            "三角函数": [
                "CORDIC算法",
                "查找表方法",
                "泰勒级数展开",
                "切比雪夫多项式逼近",
                "分段多项式逼近",
                "角度缩减与查表混合方法",
                "高阶多项式插值"
            ],
            "算术运算": [
                "基于DSP的实现",
                "流水线架构",
                "并行计算单元",
                "模冗余结构",
                "可重构计算阵列",
                "近似计算单元",
                "低功耗设计优化",
                "时分复用结构"
            ]
        }

        options = implementations.get(operation_type, ["优化实现"])
        # 随机选择一种实现方案，而不是固定选择第一个
        return random.choice(options)
