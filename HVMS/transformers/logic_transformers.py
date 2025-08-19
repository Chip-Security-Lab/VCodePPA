import re
from .transformer import BaseTransformer


class ControlFlowTransformer(BaseTransformer):
    """控制流重组变换器"""

    def is_applicable(self, code):
        """检查代码是否包含可重组的控制流"""
        try:
            # 移除注释以提高检测准确性
            clean_code = re.sub(r'//.*?\n', '\n', code)
            clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

            # 检测条件结构
            has_if_else = "if" in clean_code and "else" in clean_code
            has_case = "case" in clean_code and "endcase" in clean_code
            has_casex = "casex" in clean_code
            has_casez = "casez" in clean_code

            # 检测条件运算符
            has_conditional_op = bool(re.search(r'\?.*?:', clean_code))

            # 检测循环结构
            has_for_loop = "for" in clean_code
            has_while_loop = "while" in clean_code
            has_repeat_loop = "repeat" in clean_code

            # 检测块结构
            has_multiple_always = len(re.findall(r'always\s*@', clean_code)) > 1
            has_large_always = bool(re.search(r'always\s*@.*?begin\s*[\s\S]{500,}?\s*end', clean_code))

            # 检测复杂条件表达式
            has_complex_condition = bool(re.search(r'if\s*\([^)]{50,}\)', clean_code))

            # 综合判断是否适用于控制流重组
            return has_if_else or has_case or has_casex or has_casez or \
                has_conditional_op or has_for_loop or has_while_loop or \
                has_repeat_loop or has_multiple_always or has_large_always or \
                has_complex_condition

        except Exception as e:
            self.logger.error(f"检查控制流适用性时出错: {str(e)}")
            return False

    def get_prompt(self, code):
        """为控制流重组生成提示"""
        # 分析代码中的控制流结构
        control_structures = self._identify_control_structures(code)
        # 选择转换目标
        transform_target = self._select_transform_target(control_structures, code)

        return f"""
        你是一个专业的Verilog代码优化专家。请对下面的Verilog代码中的控制流结构进行重组，
        具体是将{transform_target['from']}结构转换为{transform_target['to']}结构，转换策略是：
        {transform_target['strategy']}

        请确保：
        1. 变换后的代码功能与原代码完全一致
        2. 控制逻辑清晰，易于理解
        3. 避免产生冗余逻辑
        4. 时序正确，无毛刺或竞争冒险
        5. 代码结构良好，易于维护
        6. 保留原代码的注释和文档

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的变换后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _identify_control_structures(self, code):
        """识别代码中的控制流结构"""
        # 移除注释以提高检测准确性
        clean_code = re.sub(r'//.*?\n', '\n', code)
        clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

        structures = {
            # 条件结构
            "if_else": {
                "present": "if" in clean_code and "else" in clean_code,
                "count": len(re.findall(r'\bif\b', clean_code)),
                "nested": bool(re.search(r'if\s*\([^)]*\)\s*begin[\s\S]*?if\s*\(', clean_code)),
                "cascaded": len(re.findall(r'else\s*if', clean_code)) > 0
            },
            "case": {
                "present": "case" in clean_code and "endcase" in clean_code,
                "count": len(re.findall(r'\bcase\b', clean_code)),
                "complex": bool(re.search(r'case\s*\([^)]{30,}\)', clean_code))
            },
            "casex_casez": {
                "present": "casex" in clean_code or "casez" in clean_code,
                "count": len(re.findall(r'\bcasex\b|\bcasez\b', clean_code))
            },
            "conditional_op": {
                "present": bool(re.search(r'\?.*?:', clean_code)),
                "count": len(re.findall(r'\?', clean_code)),
                "complex": bool(re.search(r'[^?]*\?[^:]*:[^;]*\?', clean_code))  # 嵌套条件运算符
            },

            # 循环结构
            "for_loop": {
                "present": "for" in clean_code,
                "count": len(re.findall(r'\bfor\b', clean_code)),
                "constant_iter": bool(re.search(r'for\s*\([^;]*;\s*[^<>]*<\s*\d+\s*;', clean_code))
            },
            "while_loop": {
                "present": "while" in clean_code,
                "count": len(re.findall(r'\bwhile\b', clean_code))
            },
            "repeat_loop": {
                "present": "repeat" in clean_code,
                "count": len(re.findall(r'\brepeat\b', clean_code))
            },

            # 块结构
            "always_block": {
                "present": "always" in clean_code,
                "count": len(re.findall(r'\balways\b', clean_code)),
                "large": bool(re.search(r'always\s*@.*?begin\s*[\s\S]{500,}?\s*end', clean_code))
            },

            # 复杂表达式
            "complex_condition": {
                "present": bool(re.search(r'if\s*\([^)]{50,}\)', clean_code)) or
                           bool(re.search(r'[&|^~].*[&|^~].*[&|^~]', clean_code)),
                "count": len(re.findall(r'[&|^~].*[&|^~].*[&|^~]', clean_code))
            }
        }

        self.logger.info(f"识别到的控制结构: {[k for k, v in structures.items() if v['present']]}")
        return structures

    def _select_transform_target(self, structures, code):
        """选择转换目标"""
        import random

        # 根据代码的控制流结构选择合适的转换
        transformations = []

        # 条件分支转换
        if structures["if_else"]["present"]:
            if structures["if_else"]["cascaded"] and not structures["case"]["present"]:
                transformations.append({
                    "from": "if-else级联",
                    "to": "case语句",
                    "weight": 3,
                    "strategy": "提取共同的条件变量，将if-else级联结构转换为case语句，每个条件对应一个case分支"
                })
            elif structures["if_else"]["nested"]:
                transformations.append({
                    "from": "嵌套if-else",
                    "to": "扁平化if-else",
                    "weight": 2,
                    "strategy": "将嵌套的if-else结构展开为扁平化的多条件if-else，使用逻辑与(&&)组合条件"
                })
            elif not structures["conditional_op"]["present"]:
                transformations.append({
                    "from": "if-else",
                    "to": "条件运算符(? :)",
                    "weight": structures["if_else"]["count"],
                    "strategy": "将简单的if-else赋值转换为条件运算符表达式，减少代码冗余"
                })

        # 条件运算符转换
        if structures["conditional_op"]["present"]:
            transformations.append({
                "from": "条件运算符(? :)",
                "to": "if-else",
                "weight": structures["conditional_op"]["count"],
                "strategy": "将条件运算符表达式展开为完整的if-else结构，提高代码可读性"
            })

        # Case语句转换
        if structures["case"]["present"]:
            transformations.append({
                "from": "case语句",
                "to": "if-else级联",
                "weight": structures["case"]["count"],
                "strategy": "将case语句转换为一系列的if-else if语句，每个case分支对应一个条件分支"
            })

        # CaseX/CaseZ转换
        if structures["casex_casez"]["present"]:
            transformations.append({
                "from": "casex/casez语句",
                "to": "普通case加条件判断",
                "weight": structures["casex_casez"]["count"] * 2,
                "strategy": "将casex/casez语句转换为普通case语句，使用额外的条件判断处理不确定位"
            })

        # 循环转换
        if structures["for_loop"]["present"]:
            if structures["for_loop"]["constant_iter"]:
                transformations.append({
                    "from": "for循环",
                    "to": "展开的重复语句",
                    "weight": 2,
                    "strategy": "识别具有固定迭代次数的for循环，将循环体展开为重复语句，每次迭代使用适当的索引值"
                })
            else:
                transformations.append({
                    "from": "for循环",
                    "to": "while循环",
                    "weight": 1,
                    "strategy": "将for循环转换为等价的while循环，将初始化放在循环前，迭代步骤放在循环体末尾"
                })

        if structures["while_loop"]["present"]:
            transformations.append({
                "from": "while循环",
                "to": "for循环",
                "weight": 1,
                "strategy": "将while循环转换为等价的for循环，识别循环变量和条件判断模式"
            })

            transformations.append({
                "from": "while循环",
                "to": "状态机实现",
                "weight": 2,
                "strategy": "将while循环转换为状态机结构，使用状态变量跟踪循环进度，每个循环迭代成为一个状态转换"
            })

        if structures["repeat_loop"]["present"]:
            transformations.append({
                "from": "repeat循环",
                "to": "for循环",
                "weight": 1,
                "strategy": "将repeat循环转换为等价的for循环，使用计数变量控制迭代次数"
            })

        # 块结构转换
        if structures["always_block"]["present"] and structures["always_block"]["count"] > 1:
            transformations.append({
                "from": "多个always块",
                "to": "合并的always块",
                "weight": 1,
                "strategy": "将具有相同触发条件的多个always块合并为一个单一的always块，保持逻辑顺序"
            })

        if structures["always_block"]["large"]:
            transformations.append({
                "from": "大的always块",
                "to": "多个小的always块",
                "weight": 2,
                "strategy": "将大的always块分解为多个功能独立的小always块，提高模块化和可维护性"
            })

        # 复杂条件转换
        if structures["complex_condition"]["present"]:
            transformations.append({
                "from": "复杂条件表达式",
                "to": "简化的多级条件",
                "weight": 2,
                "strategy": "将复杂的条件表达式分解为多个简单的条件判断，引入中间变量以提高可读性和综合效果"
            })

            transformations.append({
                "from": "复杂条件逻辑",
                "to": "查找表实现",
                "weight": 1,
                "strategy": "将复杂的条件逻辑转换为预计算的查找表结构，使用索引访问快速获取结果"
            })

        # 如果没有找到合适的转换，使用默认转换
        if not transformations:
            transformations.append({
                "from": "if-else",
                "to": "case语句",
                "weight": 1,
                "strategy": "将条件判断相似的if-else结构转换为case语句，提高代码的结构性"
            })

            transformations.append({
                "from": "case语句",
                "to": "if-else级联",
                "weight": 1,
                "strategy": "将case语句转换为一系列if-else if语句，每个case分支对应一个条件分支"
            })

        # 根据权重随机选择一个转换目标
        weights = [t["weight"] for t in transformations]
        selected_transform = random.choices(transformations, weights=weights, k=1)[0]

        self.logger.info(f"选择的转换: {selected_transform['from']} → {selected_transform['to']}")
        return selected_transform


class OperatorRewriteTransformer(BaseTransformer):
    """运算符重写变换器 - 专注于表达式级别的优化"""

    def is_applicable(self, code):
        """检查代码是否包含可重写的运算符表达式"""
        try:
            # 清理代码，移除注释
            clean_code = re.sub(r'//.*?\n', '\n', code)
            clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

            # 检测表达式级的操作符模式，而非整体计算单元
            patterns = {
                # 位运算符
                'bitwise_and': r'[^&]&[^&=]',  # 位与，排除&&和&=
                'bitwise_or': r'[^|]\|[^|=]',  # 位或，排除||和|=
                'bitwise_xor': r'\^[^=]',  # 位异或，排除^=
                'bitwise_not': r'~',  # 位非
                'shift_left': r'<<[^=]',  # 左移，排除<<=
                'shift_right': r'>>[^=]',  # 右移，排除>>=

                # 逻辑运算符
                'logical_and': r'&&',  # 逻辑与
                'logical_or': r'\|\|',  # 逻辑或
                'logical_not': r'!',  # 逻辑非

                # 关系运算符
                'equal': r'==',  # 相等
                'not_equal': r'!=',  # 不等
                'greater': r'(?<![><:=!])>[^>=]',  # 大于，排除>=和=>
                'less': r'(?<![><:=!])<[^<=]',  # 小于，排除<=和=
                'greater_equal': r'>=',  # 大于等于
                'less_equal': r'<=',  # 小于等于

                # 条件运算符
                'conditional': r'\?.*?:',  # 三元条件

                # 位拼接和位选择
                'concatenation': r'\{.*?\}',  # 位拼接
                'bit_select': r'\[[^\]]+\]',  # 位选择

                # 表达式优化目标
                'complex_expr': r'[&|^~]+.*?[&|^~]+.*?[&|^~]+',  # 复杂位表达式
                'comparison_chain': r'if\s*\([^)]*?(==|!=|>|<|>=|<=)[^)]*?(==|!=|>|<|>=|<=)'  # 比较链
            }

            # 查找各类操作符
            found_operators = {}
            for op_type, pattern in patterns.items():
                matches = re.findall(pattern, clean_code)
                found_operators[op_type] = len(matches)

            # 检查特定模式
            has_complex_condition = bool(re.search(r'if\s*\([^)]{50,}\)', clean_code))
            has_redundant_ops = bool(re.search(r'(~\s*~|\|\s*\&\s*\||\&\s*\|\s*\&)', clean_code))
            has_simplifiable = bool(re.search(r'[a-zA-Z_]\w*\s*(\&\s*-1|\|\s*0|\^\s*0)', clean_code))

            # 记录检测到的操作符
            self.detected_operators = {k: v for k, v in found_operators.items() if v > 0}
            self.special_patterns = {
                'complex_condition': has_complex_condition,
                'redundant_ops': has_redundant_ops,
                'simplifiable': has_simplifiable
            }

            # 判断是否有可重写的表达式级操作符
            has_bitwise = any(
                found_operators[op] > 0 for op in ['bitwise_and', 'bitwise_or', 'bitwise_xor', 'bitwise_not'])
            has_shifts = any(found_operators[op] > 0 for op in ['shift_left', 'shift_right'])
            has_logical = any(found_operators[op] > 0 for op in ['logical_and', 'logical_or', 'logical_not'])
            has_relational = any(found_operators[op] > 0 for op in
                                 ['equal', 'not_equal', 'greater', 'less', 'greater_equal', 'less_equal'])
            has_conditional = found_operators['conditional'] > 0
            has_bit_ops = found_operators['concatenation'] > 0 or found_operators['bit_select'] > 0
            has_optimizable = has_complex_condition or has_redundant_ops or has_simplifiable

            # ComputationUnitTransformer已处理的算术运算不在此变换器中考虑
            return has_bitwise or has_shifts or has_logical or has_relational or has_conditional or has_bit_ops or has_optimizable

        except Exception as e:
            self.logger.error(f"检查操作符适用性时出错: {str(e)}")
            return False

    def get_prompt(self, code):
        """为运算符重写生成提示"""
        # 分析当前代码中的操作符类型
        operation_types = self._identify_operations(code)
        # 选择转换目标
        transform_target = self._select_transform_target(operation_types)

        return f"""
        你是一个专业的Verilog代码优化专家。请对下面的Verilog代码中的{transform_target['from']}
        进行重写，使用{transform_target['to']}实现相同的功能。

        转换策略：{transform_target['strategy']}

        技术细节：
        {transform_target['details']}

        请确保：
        1. 变换后的代码功能与原代码完全一致
        2. 运算结果的位宽和符号性与原代码相同
        3. 尽可能提高代码的清晰度和效率
        4. 使用更优的表达式或实现方式
        5. 保持时序正确性，避免产生毛刺或竞争冒险
        6. 保留原代码的注释和文档

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的变换后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _identify_operations(self, code):
        """识别代码中的操作符类型和模式"""
        try:
            # 清理代码，移除注释
            clean_code = re.sub(r'//.*?\n', '\n', code)
            clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

            # 检测位运算
            bit_ops = {
                "位与": len(re.findall(r'[^&]&[^&=]', clean_code)),
                "位或": len(re.findall(r'[^|]\|[^|=]', clean_code)),
                "位异或": len(re.findall(r'\^[^=]', clean_code)),
                "位非": len(re.findall(r'~', clean_code))
            }

            # 检测移位操作
            shift_ops = {
                "左移": len(re.findall(r'<<[^=]', clean_code)),
                "右移": len(re.findall(r'>>[^=]', clean_code)),
                "变量左移": len(re.findall(r'<<\s*(\w+)', clean_code)),
                "变量右移": len(re.findall(r'>>\s*(\w+)', clean_code))
            }

            # 检测逻辑运算
            logic_ops = {
                "逻辑与": len(re.findall(r'&&', clean_code)),
                "逻辑或": len(re.findall(r'\|\|', clean_code)),
                "逻辑非": len(re.findall(r'!', clean_code))
            }

            # 检测条件运算符
            conditional_ops = {
                "三元运算符": len(re.findall(r'\?.*?:', clean_code)),
                "嵌套三元": len(re.findall(r'[^?]*\?[^:]*:[^;]*\?', clean_code))
            }

            # 检测比较操作
            comparison_ops = {
                "等于": len(re.findall(r'==', clean_code)),
                "不等于": len(re.findall(r'!=', clean_code)),
                "大于": len(re.findall(r'(?<![><:=!])>[^>=]', clean_code)),
                "小于": len(re.findall(r'(?<![><:=!])<[^<=]', clean_code)),
                "大于等于": len(re.findall(r'>=', clean_code)),
                "小于等于": len(re.findall(r'<=', clean_code)),
                "比较链": len(re.findall(r'if\s*\([^)]*?(==|!=|>|<|>=|<=)[^)]*?(==|!=|>|<|>=|<=)', clean_code))
            }

            # 检测位操作
            bit_manipulation = {
                "位拼接": len(re.findall(r'\{.*?\}', clean_code)),
                "位选择": len(re.findall(r'\[[^\]]+\]', clean_code))
            }

            # 检测复杂条件和可优化表达式
            optimizable = {
                "复杂条件": len(re.findall(r'if\s*\([^)]{50,}\)', clean_code)),
                "冗余操作": len(re.findall(r'(~\s*~|\|\s*\&\s*\||\&\s*\|\s*\&)', clean_code)),
                "可简化表达式": len(re.findall(r'[a-zA-Z_]\w*\s*(\&\s*-1|\|\s*0|\^\s*0)', clean_code))
            }

            return {
                "位运算": bit_ops,
                "移位": shift_ops,
                "逻辑运算": logic_ops,
                "条件运算符": conditional_ops,
                "比较操作": comparison_ops,
                "位操作": bit_manipulation,
                "可优化": optimizable
            }

        except Exception as e:
            self.logger.error(f"识别操作类型时出错: {str(e)}")
            return {}

    def _select_transform_target(self, operations):
        """选择转换目标"""
        import random

        # 可能的转换目标列表
        transformations = []

        # 1. 位运算优化
        if sum(operations.get("位运算", {}).values()) > 0:
            # 位运算简化
            transformations.append({
                "from": "复杂位运算表达式",
                "to": "简化的布尔表达式",
                "weight": sum(operations.get("位运算", {}).values()),
                "strategy": "应用布尔代数规则简化位运算表达式",
                "details": "使用布尔代数恒等式和规则重写位运算表达式，如德摩根定律(~(A|B) = ~A & ~B, ~(A&B) = ~A | ~B)、吸收律(A|(A&B) = A)、分配律等，减少操作数量和逻辑深度。"
            })

            # 位运算替换
            if operations.get("位运算", {}).get("位异或", 0) > 0:
                transformations.append({
                    "from": "异或运算",
                    "to": "与或非组合",
                    "weight": operations.get("位运算", {}).get("位异或", 0),
                    "strategy": "将异或操作转换为与、或、非的组合",
                    "details": "异或操作A^B可以表示为(A&~B)|(~A&B)，在某些硬件架构上这种转换可能更高效。对于多输入异或，可以重写为奇偶校验树结构。"
                })

        # 2. 移位操作优化
        if sum(operations.get("移位", {}).values()) > 0:
            if operations.get("移位", {}).get("变量左移", 0) > 0 or operations.get("移位", {}).get("变量右移", 0) > 0:
                transformations.append({
                    "from": "变量移位操作",
                    "to": "桶形移位器",
                    "weight": operations.get("移位", {}).get("变量左移", 0) + operations.get("移位", {}).get("变量右移",
                                                                                                             0),
                    "strategy": "使用桶形移位器结构重写变量移位操作",
                    "details": "桶形移位器通过多级多路复用器实现可变移位，每级控制不同位数的移位。这种结构可以高效处理变量移位量，适合需要支持各种移位量的场景。"
                })

            if operations.get("移位", {}).get("左移", 0) > operations.get("移位", {}).get("变量左移", 0) or \
                    operations.get("移位", {}).get("右移", 0) > operations.get("移位", {}).get("变量右移", 0):
                transformations.append({
                    "from": "常数移位操作",
                    "to": "位拼接操作",
                    "weight": 2,
                    "strategy": "将常数移位转换为位拼接操作",
                    "details": "常数左移可以使用位拼接实现，如a << 2等价于{a, 2'b0}；常数右移可以使用位选择实现，如a >> 2等价于{2'b0, a[WIDTH-1:2]}。这种转换通常可以在综合时产生更优的硬件结构。"
                })

        # 3. 逻辑运算优化
        if sum(operations.get("逻辑运算", {}).values()) > 0:
            if operations.get("逻辑运算", {}).get("逻辑与", 0) > 0 and operations.get("逻辑运算", {}).get("逻辑或",
                                                                                                          0) > 0:
                transformations.append({
                    "from": "复杂逻辑表达式",
                    "to": "优化的逻辑结构",
                    "weight": operations.get("逻辑运算", {}).get("逻辑与", 0) + operations.get("逻辑运算", {}).get(
                        "逻辑或", 0),
                    "strategy": "重组复杂逻辑表达式以减少求值路径",
                    "details": "将复杂逻辑表达式重组，将计算成本较低或更可能提前确定结果的条件放在前面，利用短路求值特性优化性能。例如，对于A&&B&&C，如果A计算成本低且更可能为假，应该放在前面。"
                })

        # 4. 条件运算符优化
        if operations.get("条件运算符", {}).get("三元运算符", 0) > 0:
            if operations.get("条件运算符", {}).get("嵌套三元", 0) > 0:
                transformations.append({
                    "from": "嵌套三元运算符",
                    "to": "if-else结构",
                    "weight": operations.get("条件运算符", {}).get("嵌套三元", 0) * 2,
                    "strategy": "将嵌套的三元运算符转换为清晰的if-else结构",
                    "details": "嵌套的三元运算符通常难以理解和维护，转换为if-else结构可以提高代码可读性，同时在硬件实现上可能产生更优的结构。"
                })
            else:
                transformations.append({
                    "from": "三元运算符",
                    "to": "多路复用器结构",
                    "weight": operations.get("条件运算符", {}).get("三元运算符", 0),
                    "strategy": "将三元运算符显式转换为多路复用器结构",
                    "details": "将条件运算符cond ? a : b转换为assign result = cond ? a : b或显式多路复用器实现，使意图更明确并可能在综合时产生更优的结构。"
                })

        # 5. 比较操作优化
        if operations.get("比较操作", {}).get("比较链", 0) > 0:
            transformations.append({
                "from": "复杂比较链",
                "to": "优化决策树",
                "weight": operations.get("比较操作", {}).get("比较链", 0) * 2,
                "strategy": "将多个比较操作重组为优化的决策树结构",
                "details": "将连续的比较操作重组为决策树结构，根据条件概率或计算成本优化分支顺序，减少平均评估路径。对于范围检查，可以转换为区间比较而非多个独立比较。"
            })

        # 6. 位操作优化
        if operations.get("位操作", {}).get("位拼接", 0) > 0:
            transformations.append({
                "from": "复杂位拼接",
                "to": "简化位操作",
                "weight": operations.get("位操作", {}).get("位拼接", 0),
                "strategy": "简化和优化位拼接操作",
                "details": "合并多次位拼接为单次操作，移除冗余的位选择和拼接，使用参数化的位宽定义提高可维护性。对于固定模式的位拼接，考虑使用常量或宏替代。"
            })

        # 7. 可优化表达式变换
        if operations.get("可优化", {}).get("复杂条件", 0) > 0:
            transformations.append({
                "from": "复杂条件表达式",
                "to": "分解的条件逻辑",
                "weight": operations.get("可优化", {}).get("复杂条件", 0) * 2,
                "strategy": "将复杂条件分解为中间变量和简单条件",
                "details": "将大型复杂条件表达式分解为多个中间布尔变量，然后在最终条件中使用这些变量，提高可读性和维护性，同时可能优化硬件实现。"
            })

        if operations.get("可优化", {}).get("冗余操作", 0) > 0:
            transformations.append({
                "from": "冗余位操作",
                "to": "简化表达式",
                "weight": operations.get("可优化", {}).get("冗余操作", 0) * 3,
                "strategy": "移除或简化冗余的位操作",
                "details": "识别并消除逻辑上冗余的位操作，如~~a (等同于a)、a&a (等同于a)、a|a (等同于a)、a^a (等同于0)、a&1 (等同于a)、a|0 (等同于a)等。"
            })

        # 如果没有找到合适的转换，提供默认选项
        if not transformations:
            transformations = [
                {
                    "from": "常规位操作",
                    "to": "优化的位操作",
                    "weight": 1,
                    "strategy": "应用位操作优化技术",
                    "details": "分析代码中的位操作模式，应用适当的优化技术如布尔简化、常量折叠、公共子表达式提取等。"
                },
                {
                    "from": "条件逻辑",
                    "to": "优化的条件结构",
                    "weight": 1,
                    "strategy": "优化条件逻辑结构",
                    "details": "重组条件逻辑以提高效率，可能包括条件重排序、合并相似条件、移除冗余检查等。"
                }
            ]

        # 根据权重随机选择一个转换目标
        weights = [t["weight"] for t in transformations]
        selected_transform = random.choices(transformations, weights=weights, k=1)[0]

        self.logger.info(f"选择的操作符转换: {selected_transform['from']} → {selected_transform['to']}")
        return selected_transform


class LogicLayerTransformer(BaseTransformer):
    """逻辑层次重组变换器"""

    def is_applicable(self, code):
        """检查代码是否适合逻辑层次重组"""
        try:
            # 清理代码，移除注释
            clean_code = re.sub(r'//.*?\n', '\n', code)
            clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

            # 检查代码规模
            code_size = len(clean_code)

            # 检查always块特征
            always_blocks = re.findall(r'always\s*@', clean_code)
            has_multiple_always = len(always_blocks) > 1
            has_large_always = bool(re.search(r'always\s*@.*?begin\s*[\s\S]{500,}?\s*end', clean_code))

            # 检查组合逻辑和时序逻辑混合
            has_combo_logic = "assign" in clean_code
            has_seq_logic = bool(re.search(r'always\s*@\s*\([^)]*posedge[^)]*\)', clean_code))
            has_mixed_logic = has_combo_logic and has_seq_logic

            # 检查模块复杂度
            has_complex_module = code_size > 1000 or has_large_always

            # 检查是否有重复代码模式
            # 提取常见代码块并检查重复
            code_blocks = re.findall(r'begin\s*([\s\S]{20,200}?)\s*end', clean_code)
            has_duplicate_patterns = False

            if len(code_blocks) > 1:
                # 简化代码块用于比较
                simplified_blocks = [re.sub(r'\s+', ' ', block).strip() for block in code_blocks]
                # 检查是否有相似代码块
                for i in range(len(simplified_blocks)):
                    for j in range(i + 1, len(simplified_blocks)):
                        similarity = self._calculate_similarity(simplified_blocks[i], simplified_blocks[j])
                        if similarity > 0.7:  # 70%相似度阈值
                            has_duplicate_patterns = True
                            break
                    if has_duplicate_patterns:
                        break

            # 检查数据流路径
            # 查找长信号链路或复杂信号连接
            has_complex_data_path = len(re.findall(r'assign\s+\w+\s*=\s*[^;]{100,}', clean_code)) > 0

            # 检查寄存器传输路径
            reg_transfers = re.findall(r'\w+\s*<=\s*\w+', clean_code)
            has_multiple_reg_transfers = len(reg_transfers) > 5

            # 记录检测到的特征
            self.code_features = {
                "code_size": code_size,
                "always_count": len(always_blocks),
                "has_large_always": has_large_always,
                "has_mixed_logic": has_mixed_logic,
                "has_complex_module": has_complex_module,
                "has_duplicate_patterns": has_duplicate_patterns,
                "has_complex_data_path": has_complex_data_path,
                "has_multiple_reg_transfers": has_multiple_reg_transfers
            }

            self.logger.info(f"代码特征检测结果: {self.code_features}")

            # 综合判断是否适用于逻辑层次重组
            return (has_complex_module or has_multiple_always or
                    has_mixed_logic or has_duplicate_patterns or
                    has_complex_data_path or has_multiple_reg_transfers)

        except Exception as e:
            self.logger.error(f"检查逻辑层次适用性时出错: {str(e)}")
            return False

    def get_prompt(self, code):
        """为逻辑层次重组生成提示"""
        # 分析代码的逻辑结构
        logic_structure = self._analyze_logic_structure(code)
        # 选择转换策略
        transform_strategy = self._select_transform_strategy(logic_structure)

        # 安全检查transform_strategy
        if transform_strategy is None:
            self.logger.error("未能选择有效的转换策略")
            # 提供一个默认策略，避免后续代码出错
            transform_strategy = {
                "description": "一般性的模块结构优化",
                "from": "现有模块结构",
                "to": "优化的模块架构",
                "strategy": "提高整体代码的模块化程度，重组信号流和控制流",
                "considerations": "保持代码可读性和可维护性，遵循良好的Verilog设计实践"
            }

        return f"""
        你是一个专业的Verilog代码架构设计专家。请对下面的Verilog代码的逻辑层次结构进行重组，
        执行以下变换：{transform_strategy['description']}

        变换目标：将{transform_strategy['from']}结构重组为{transform_strategy['to']}结构

        变换策略详情：
        {transform_strategy['strategy']}

        设计考虑：
        {transform_strategy.get('considerations', '保持代码可读性和可维护性')}

        请确保：
        1. 变换后的代码功能与原代码完全一致
        2. 代码结构更清晰，模块化程度更高
        3. 信号命名保持一致或更有意义
        4. 时序正确，无意外的亚稳态或竞争冒险
        5. 保持代码可读性和可维护性
        6. 代码中适当添加注释，解释模块功能和接口

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的变换后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _calculate_similarity(self, str1, str2):
        """计算两个字符串的相似度"""
        from difflib import SequenceMatcher
        return SequenceMatcher(None, str1, str2).ratio()

    def _analyze_logic_structure(self, code):
        """分析代码的逻辑结构"""
        try:
            # 清理代码，移除注释
            clean_code = re.sub(r'//.*?\n', '\n', code)
            clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

            structure = {}

            # 提取模块名称
            module_match = re.search(r'module\s+(\w+)', clean_code)
            structure['module_name'] = module_match.group(1) if module_match else "unknown_module"

            # 分析always块
            always_blocks = re.findall(r'always\s*@\s*\([^)]*\)([\s\S]*?end)', clean_code)
            structure['always_block_count'] = len(always_blocks)
            structure['average_always_size'] = sum(len(block) for block in always_blocks) / max(1, len(always_blocks))
            structure['large_always_block'] = any(len(block) > 500 for block in always_blocks)

            # 分析组合逻辑和时序逻辑
            assign_blocks = re.findall(r'assign\s+[^;]*;', clean_code)
            structure['assign_count'] = len(assign_blocks)
            structure['sequential_blocks'] = len(re.findall(r'always\s*@\s*\([^)]*posedge[^)]*\)', clean_code))
            structure['combinational_blocks'] = len(re.findall(r'always\s*@\s*\(\s*\*\s*\)', clean_code))
            structure['mixed_logic'] = structure['sequential_blocks'] > 0 and (
                    structure['assign_count'] > 0 or structure['combinational_blocks'] > 0)

            # 检测重复代码模式
            code_blocks = re.findall(r'begin\s*([\s\S]{20,200}?)\s*end', clean_code)
            simplified_blocks = [re.sub(r'\s+', ' ', block).strip() for block in code_blocks]

            similar_blocks = []
            for i in range(len(simplified_blocks)):
                for j in range(i + 1, len(simplified_blocks)):
                    similarity = self._calculate_similarity(simplified_blocks[i], simplified_blocks[j])
                    if similarity > 0.7:
                        similar_blocks.append((i, j, similarity))

            structure['similar_blocks'] = similar_blocks
            structure['has_duplicate_patterns'] = len(similar_blocks) > 0

            # 分析数据路径
            long_assignments = re.findall(r'assign\s+\w+\s*=\s*[^;]{100,}', clean_code)
            structure['complex_data_paths'] = len(long_assignments)

            # 代码复杂度分析
            structure['code_size'] = len(clean_code)
            structure['complex_module'] = structure['code_size'] > 1000

            return structure
        except Exception as e:
            self.logger.error(f"分析逻辑结构时出错: {str(e)}")
            # 返回一个基本结构，防止后续操作出错
            return {
                'module_name': 'unknown_module',
                'always_block_count': 0,
                'average_always_size': 0,
                'large_always_block': False,
                'assign_count': 0,
                'sequential_blocks': 0,
                'combinational_blocks': 0,
                'mixed_logic': False,
                'similar_blocks': [],
                'has_duplicate_patterns': False,
                'complex_data_paths': 0,
                'code_size': len(code),
                'complex_module': False
            }

    def _select_transform_strategy(self, structure):
        """根据代码结构选择转换策略"""
        import random

        # 安全检查 - 确保structure不为None
        if structure is None:
            self.logger.error("逻辑结构为None，无法选择转换策略")
            return None

        # 转换策略列表
        strategies = []

        # 1. 模块分解策略
        if structure.get('complex_module', False) or structure.get('code_size', 0) > 1000:
            strategies.append({
                "type": "module_decomposition",
                "from": "扁平化大型模块",
                "to": "层次化子模块结构",
                "weight": 3 if structure.get('code_size', 0) > 1500 else 2,
                "description": "将大型扁平化模块分解为多个功能子模块",
                "strategy": """
                1. 分析模块的功能边界，按照功能相关性划分成多个逻辑单元
                2. 为每个逻辑单元创建独立的子模块，定义清晰的输入输出接口
                3. 将原模块重构为顶层模块，实例化各个子模块并连接它们
                4. 确保子模块之间的接口最小化且明确
                5. 为每个子模块添加合适的注释，说明其功能和用途
                """,
                "considerations": """
                - 子模块应当功能单一，接口简洁
                - 模块间的连接应当明确，避免过多的全局信号
                - 相关信号应当分组，使用结构化的命名约定
                - 考虑参数化设计以提高可复用性
                - 同类操作应当放在同一个子模块中
                """
            })

        # 2. 逻辑分离策略
        if structure.get('mixed_logic', False):
            strategies.append({
                "type": "logic_separation",
                "from": "混合的组合逻辑和时序逻辑",
                "to": "分离的组合逻辑和时序逻辑结构",
                "weight": 2,
                "description": "将组合逻辑和时序逻辑分离到不同的模块或代码块",
                "strategy": """
                1. 识别模块中的组合逻辑部分和时序逻辑部分
                2. 将组合逻辑重构为独立的always块或assign语句
                3. 将时序逻辑集中到时钟触发的always块中
                4. 确保组合逻辑的输出正确连接到时序逻辑
                5. 考虑将纯组合逻辑部分移到单独的模块中
                """,
                "considerations": """
                - 组合逻辑应使用assign语句或always @(*)块
                - 时序逻辑应仅在时钟边沿触发的always块中
                - 避免在时序逻辑中产生锁存器
                - 明确区分寄存器信号和线网信号
                - 考虑重命名信号以区分组合结果和寄存器值
                """
            })

        # 3. 功能封装策略
        if structure.get('has_duplicate_patterns', False) and len(structure.get('similar_blocks', [])) > 0:
            strategies.append({
                "type": "function_encapsulation",
                "from": "含有重复逻辑的代码",
                "to": "使用可复用模块的结构",
                "weight": len(structure.get('similar_blocks', [])),
                "description": "将重复的逻辑代码提取为可复用的功能模块",
                "strategy": """
                1. 识别代码中的重复逻辑模式和相似功能块
                2. 设计通用参数化接口，允许处理各种情况
                3. 创建新的子模块，实现这些重复功能
                4. 将原代码中的重复部分替换为子模块实例
                5. 确保接口参数能够适应所有使用场景
                """,
                "considerations": """
                - 子模块应当足够通用以处理所有变种情况
                - 使用参数和生成语句增强灵活性
                - 保持接口简单明了
                - 确保时序要求在封装过程中得到保持
                - 考虑使用任务或函数处理非常小的重复逻辑
                """
            })

        # 4. Always块重组策略
        if structure.get('large_always_block', False) or structure.get('always_block_count', 0) > 3:
            # 根据是否有大型always块选择不同的描述和策略
            if structure.get('large_always_block', False):
                description = "将大型always块拆分为多个合理大小的always块"
                strategy = """
                1. 根据功能将大型always块拆分为多个小块
                2. 确保每个always块只处理特定的相关信号组
                3. 使每个always块有明确的功能边界
                4. 重新组织触发条件，使其更精确
                5. 为每个always块添加功能说明注释
                """
                considerations = """
                - 每个always块应当功能单一
                - 尽量避免一个信号在多个always块中被赋值
                - 触发条件应当精确，只包含必要的信号
                - 考虑不同块之间的信号依赖关系
                - 先处理优先级高的逻辑
                """
            else:
                description = "合并相关的小型always块为逻辑凝聚的块"
                strategy = """
                1. 识别功能相关的always块
                2. 合并触发条件相同的always块
                3. 按照信号关联性重组always块
                4. 移除冗余或重复的逻辑
                5. 使always块的功能更加内聚
                """
                considerations = """
                - 合并块时保持功能逻辑的关联性
                - 避免创建过于复杂的触发条件
                - 保持代码可读性，不要为了合并而牺牲清晰度
                - 考虑分组相关信号的赋值
                - 确保合并不会引入新的时序问题
                """

            strategies.append({
                "type": "always_block_reorganization",
                "from": "不合理的always块结构",
                "to": "优化的always块组织",
                "weight": 2,
                "description": description,
                "strategy": strategy,
                "considerations": considerations
            })

        # 5. 数据通路重构策略
        if structure.get('complex_data_paths', 0) > 0 or structure.get('code_size', 0) > 800:
            strategies.append({
                "type": "datapath_restructuring",
                "from": "混乱的数据流路径",
                "to": "结构化的数据通路",
                "weight": structure.get('complex_data_paths', 0) + 1,
                "description": "重新组织数据流路径，提高信号传递的清晰度",
                "strategy": """
                1. 分析数据流的主要路径和瓶颈
                2. 在长路径中添加适当的寄存器级，分割复杂路径
                3. 重新组织数据流，形成清晰的流水线结构
                4. 为主要数据路径增加清晰的命名和文档
                5. 重组复杂的组合逻辑路径，减少逻辑深度
                """,
                "considerations": """
                - 添加的寄存器应当在适当位置切分数据路径
                - 确保流水线级数和时序约束匹配
                - 使用一致的命名约定表示数据流阶段
                - 考虑重组后的资源使用和时序影响
                - 平衡延迟和吞吐量需求
                """
            })

        # 如果没有特定策略适用，提供默认选项
        if not strategies:
            strategies = [
                {
                    "type": "general_restructuring",
                    "from": "现有模块结构",
                    "to": "优化的模块架构",
                    "weight": 1,
                    "description": "进行一般性的模块结构优化",
                    "strategy": """
                1. 提高整体代码的模块化程度
                2. 将相关功能分组到逻辑单元
                3. 优化信号流和控制流
                4. 改善命名约定和文档
                5. 消除冗余逻辑
                """,
                    "considerations": """
                - 保持代码可读性和可维护性
                - 遵循良好的Verilog设计实践
                - 适当添加注释以解释设计意图
                - 优化资源使用和性能
                - 确保功能正确性
                """
                }
            ]

        # 安全检查 - 确保strategies不为空
        if not strategies:
            self.logger.warning("未找到适用的策略，使用默认策略")
            return {
                "type": "general_restructuring",
                "from": "现有模块结构",
                "to": "优化的模块架构",
                "weight": 1,
                "description": "进行一般性的模块结构优化",
                "strategy": "提高整体代码的模块化程度，重组信号流和控制流",
                "considerations": "保持代码可读性和可维护性，遵循良好的Verilog设计实践"
            }

        # 根据权重随机选择一个转换策略
        try:
            weights = [s.get("weight", 1) for s in strategies]
            selected_strategy = random.choices(strategies, weights=weights, k=1)[0]
            self.logger.info(
                f"选择的层次变换策略: {selected_strategy.get('type', 'unknown')} - {selected_strategy.get('description', 'unknown')}")
            return selected_strategy
        except Exception as e:
            self.logger.error(f"选择转换策略时出错: {str(e)}")
            # 发生错误时返回第一个策略，或者默认策略
            if strategies:
                return strategies[0]
            else:
                return {
                    "type": "general_restructuring",
                    "from": "现有模块结构",
                    "to": "优化的模块架构",
                    "weight": 1,
                    "description": "进行一般性的模块结构优化",
                    "strategy": "提高整体代码的模块化程度，重组信号流和控制流",
                    "considerations": "保持代码可读性和可维护性，遵循良好的Verilog设计实践"
                }
