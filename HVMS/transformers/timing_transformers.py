import re
from .transformer import BaseTransformer

import re
import random
from .transformer import BaseTransformer


class CriticalPathTransformer(BaseTransformer):
    """关键路径切割变换器 - 专注于减少组合逻辑路径延迟"""

    def is_applicable(self, code):
        """检查代码是否适合关键路径切割"""
        try:
            # 清理代码，移除注释
            clean_code = re.sub(r'//.*?\n', '\n', code)
            clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

            # 检查是否有时序逻辑（时钟）
            has_clock = bool(re.search(r'posedge\s+\w+', clean_code))
            if not has_clock:
                self.logger.info("代码中未检测到时钟，不适用于关键路径优化")
                return False

            # 检查是否有复杂的组合逻辑路径
            operators = re.findall(r'[&|^~+\-*/%]', clean_code)
            complex_expressions = re.findall(r'assign\s+\w+\s*=\s*[^;]{50,}', clean_code)
            long_always_combo = re.findall(r'always\s*@\s*\(\s*\*\s*\)[\s\S]{100,}?end', clean_code)

            has_complex_logic = len(operators) > 10 or len(complex_expressions) > 0 or len(long_always_combo) > 0

            # 检查是否有高扇出信号
            signal_patterns = re.findall(r'(\w+)(?=\s*[\[\(]|\s*[,;]|\s+(?!<=))', clean_code)
            signal_counts = {}
            for signal in signal_patterns:
                if signal not in ['if', 'else', 'case', 'endcase', 'begin', 'end', 'module', 'endmodule',
                                  'input', 'output', 'wire', 'reg', 'assign', 'always', 'posedge', 'negedge']:
                    signal_counts[signal] = signal_counts.get(signal, 0) + 1

            high_fanout_signals = [s for s, count in signal_counts.items() if count > 5]
            has_high_fanout = len(high_fanout_signals) > 0

            # 记录检测到的特征
            self.code_features = {
                "has_complex_logic": has_complex_logic,
                "has_high_fanout": has_high_fanout,
                "high_fanout_signals": high_fanout_signals[:5] if has_high_fanout else [],
                "complex_expressions_count": len(complex_expressions),
                "long_always_combo_count": len(long_always_combo)
            }

            self.logger.info(f"关键路径特征检测: {self.code_features}")

            # 判断是否适用于关键路径切割
            return has_clock and (has_complex_logic or has_high_fanout)

        except Exception as e:
            self.logger.error(f"检查关键路径适用性时出错: {str(e)}")
            return False

    def get_prompt(self, code):
        """为关键路径切割生成提示"""
        # 分析代码特征并选择最合适的切割策略
        cutting_strategy = self._select_cutting_strategy()

        return f"""
        你是一个专业的Verilog时序优化专家。请对下面的Verilog代码中的关键路径应用{cutting_strategy['name']}，
        以减少组合逻辑延迟，提高时序性能。

        优化策略：{cutting_strategy['description']}

        技术要点：
        {cutting_strategy['technical_details']}

        请确保：
        1. 变换后的代码功能与原代码完全一致
        2. {cutting_strategy['implementation_notes']}
        3. 时序逻辑正确，无毛刺或亚稳态风险
        4. 信号命名清晰且符合命名规范
        5. 保持代码可读性和可维护性

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的优化后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _select_cutting_strategy(self):
        """根据代码特征选择最合适的切割策略"""
        strategies = [
            {
                "name": "选择性关键路径切割",
                "weight": 3 if self.code_features.get("has_complex_logic", False) else 1,
                "description": "针对可能的关键路径（组合逻辑最长路径）插入流水线寄存器，减少单周期组合逻辑延迟",
                "technical_details": """
                1. 识别组合逻辑中的长路径，特别是多级运算符链或复杂表达式
                2. 在长路径的中间位置插入寄存器，将一个复杂组合逻辑分为两个或多个简单组合逻辑
                3. 需要调整控制逻辑以考虑额外的延迟周期
                4. 对于多输出逻辑，确保所有路径延迟保持一致或相应调整
                """,
                "implementation_notes": "重点关注复杂表达式和长组合逻辑路径，使用清晰命名的流水线寄存器"
            },
            {
                "name": "扇出缓冲与负载均衡",
                "weight": 5 if self.code_features.get("has_high_fanout", False) else 1,
                "description": "为高扇出信号增加缓冲寄存器，减少因扇出过大导致的延迟",
                "technical_details": """
                1. 识别扇出大的信号，特别是驱动多个目标的控制信号或数据总线
                2. 为高扇出信号添加寄存器缓冲器，分散驱动负载
                3. 对于复杂的高扇出树，考虑构建多级缓冲结构
                4. 平衡各路径的延迟，确保时序一致性
                """,
                "implementation_notes": "为以下高扇出信号添加适当的缓冲寄存器：" +
                                        (", ".join(self.code_features.get("high_fanout_signals", []))
                                         if self.code_features.get("high_fanout_signals")
                                         else "检测到的高扇出信号")
            },
            {
                "name": "路径平衡逻辑重构",
                "weight": 2,
                "description": "重组组合逻辑表达式，均衡各路径延迟，减少关键路径长度",
                "technical_details": """
                1. 分析组合逻辑结构，识别不平衡的路径
                2. 重新组织逻辑表达式，使各路径延迟更加均衡
                3. 应用逻辑等价变换，如德摩根定律、分配律等，减少逻辑深度
                4. 提前计算常量表达式，减少运行时逻辑层级
                """,
                "implementation_notes": "重组不平衡的组合逻辑，使用逻辑等价变换减少关键路径长度"
            }
        ]

        # 根据权重随机选择一个切割策略
        weights = [s["weight"] for s in strategies]
        selected_strategy = random.choices(strategies, weights=weights, k=1)[0]

        self.logger.info(f"选择的关键路径切割策略: {selected_strategy['name']}")
        return selected_strategy


import re
import random
from .transformer import BaseTransformer


class RegisterRetimingTransformer(BaseTransformer):
    """寄存器重定时变换器 - 移动现有寄存器位置以优化时序性能"""

    def is_applicable(self, code):
        """检查代码是否适合寄存器重定时"""
        try:
            # 清理代码，移除注释
            clean_code = re.sub(r'//.*?\n', '\n', code)
            clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

            # 检查是否有时序逻辑块
            sequential_blocks = re.findall(r'always\s*@\s*\([^)]*posedge[^)]*\)', clean_code)
            has_sequential = len(sequential_blocks) > 0

            if not has_sequential:
                self.logger.info("代码中未检测到时序逻辑块，不适用于寄存器重定时")
                return False

            # 检查是否有寄存器
            reg_declarations = re.findall(r'reg\s+(?:\[\s*\d+\s*:\s*\d+\s*\]\s*)?(\w+)', clean_code)
            has_registers = len(reg_declarations) > 0

            if not has_registers:
                self.logger.info("代码中未检测到寄存器声明，不适用于寄存器重定时")
                return False

            # 检查寄存器赋值模式
            reg_assignments = re.findall(r'(\w+)\s*<=', clean_code)

            # 检查组合逻辑路径
            assign_statements = re.findall(r'assign\s+(\w+)\s*=\s*([^;]+);', clean_code)
            has_combo_paths = len(assign_statements) > 0

            # 分析寄存器的位置分布
            input_near_regs = 0
            output_near_regs = 0

            # 提取模块输入输出
            inputs = re.findall(r'input\s+(?:wire\s+)?(?:\[\s*\d+\s*:\s*\d+\s*\]\s*)?(\w+)', clean_code)
            outputs = re.findall(r'output\s+(?:wire|reg)?\s+(?:\[\s*\d+\s*:\s*\d+\s*\]\s*)?(\w+)', clean_code)

            # 检查输入附近的寄存器
            for reg in reg_declarations:
                # 简单检查寄存器是否与输入相关联
                for input_signal in inputs:
                    if re.search(
                            rf'{input_signal}\s*(?:\[[^\]]+\])?\s*(?:&|\||\^|\+|-|\*|/|%|<<|>>|==|!=|<|>|<=|>=)\s*.*{reg}',
                            clean_code):
                        input_near_regs += 1
                        break

            # 检查输出附近的寄存器
            for reg in reg_declarations:
                # 检查寄存器是否直接连接到输出
                for output_signal in outputs:
                    if re.search(rf'assign\s+{output_signal}\s*=\s*{reg}', clean_code) or output_signal == reg:
                        output_near_regs += 1
                        break

            # 记录检测到的特征
            self.code_features = {
                "sequential_blocks": len(sequential_blocks),
                "registers": len(reg_declarations),
                "register_assignments": len(reg_assignments),
                "input_near_regs": input_near_regs,
                "output_near_regs": output_near_regs,
                "combo_paths": len(assign_statements)
            }

            self.logger.info(f"寄存器重定时特征检测: {self.code_features}")

            # 判断是否适合寄存器重定时
            has_regs_to_move = len(reg_declarations) > 1

            return has_sequential and has_registers and has_combo_paths and has_regs_to_move

        except Exception as e:
            self.logger.error(f"检查寄存器重定时适用性时出错: {str(e)}")
            return False

    def get_prompt(self, code):
        """为寄存器重定时生成提示"""
        # 分析代码特征并选择最合适的重定时策略
        retiming_strategy = self._select_retiming_strategy()

        return f"""
        你是一个专业的Verilog时序优化专家。请对下面的Verilog代码应用{retiming_strategy['name']}，
        通过移动现有寄存器的位置来优化时序性能，而不改变电路的功能行为。

        优化策略：{retiming_strategy['description']}

        技术要点：
        {retiming_strategy['technical_details']}

        请确保：
        1. 变换后的代码功能与原代码完全一致，电路的整体延迟特性保持不变
        2. {retiming_strategy['implementation_notes']}
        3. 保持时序逻辑的正确性，尤其是复位逻辑
        4. 所有寄存器移动都遵循数字电路时序原则，不产生非因果关系
        5. 维持代码可读性，适当添加注释说明重定时的关键点

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的优化后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _select_retiming_strategy(self):
        """根据代码特征选择最合适的重定时策略"""
        input_near_regs = self.code_features.get("input_near_regs", 0)
        output_near_regs = self.code_features.get("output_near_regs", 0)

        strategies = [
            {
                "name": "前向寄存器重定时",
                "weight": 3 if input_near_regs > output_near_regs else 1,
                "description": "将靠近输入端的寄存器向前推移穿过组合逻辑，减少输入端到第一级寄存器之间的延迟",
                "technical_details": """
                1. 识别靠近输入的寄存器（通常直接连接到输入或仅有简单组合逻辑）
                2. 将这些寄存器向数据流方向推移到组合逻辑之后
                3. 适当调整数据路径以保持功能一致
                4. 确保重定时后每条路径延迟更加平衡
                5. 保持时序约束和控制逻辑的正确性
                """,
                "implementation_notes": "特别关注输入附近的寄存器，将其移动到组合逻辑之后，确保正确处理复位逻辑"
            },
            {
                "name": "后向寄存器重定时",
                "weight": 3 if output_near_regs > input_near_regs else 1,
                "description": "将靠近输出端的寄存器向后拉移穿过组合逻辑，平衡路径延迟并减少关键路径长度",
                "technical_details": """
                1. 识别靠近输出的寄存器（通常是组合逻辑之后直接连接到输出的寄存器）
                2. 将这些寄存器向数据源方向拉移到组合逻辑之前
                3. 可能需要复制寄存器以维持多路径的正确性
                4. 调整控制逻辑以适应寄存器位置变化
                5. 确保重定时不引入功能变化或竞争风险
                """,
                "implementation_notes": "重点关注输出附近的寄存器，将其移动到组合逻辑之前，必要时复制寄存器以保持路径独立性"
            }
        ]

        # 根据权重随机选择一个重定时策略
        weights = [s["weight"] for s in strategies]
        selected_strategy = random.choices(strategies, weights=weights, k=1)[0]

        self.logger.info(f"选择的寄存器重定时策略: {selected_strategy['name']}")
        return selected_strategy


import re
import random
from .transformer import BaseTransformer


class PipelineTransformer(BaseTransformer):
    """流水线变换器 - 专注于整体流水线架构的设计与调整"""

    def is_applicable(self, code):
        """检查代码是否适合流水线变换"""
        try:
            # 清理代码，移除注释
            clean_code = re.sub(r'//.*?\n', '\n', code)
            clean_code = re.sub(r'/\*[\s\S]*?\*/', '', clean_code)

            # 检查是否有时序逻辑
            has_sequential = bool(re.search(r'always\s*@\s*\([^)]*posedge[^)]*\)', clean_code))

            if not has_sequential:
                self.logger.info("代码中未检测到时序逻辑，不适用于流水线变换")
                return False

            # 检测是否已有流水线结构
            pipeline_features = self._detect_pipeline_structure(clean_code)

            # 检查是否有足够复杂的数据路径
            complex_assigns = re.findall(r'assign\s+\w+\s*=\s*[^;]{50,}', clean_code)
            complex_always = re.findall(r'always\s*@[\s\S]{100,}?end', clean_code)

            has_complex_datapath = len(complex_assigns) > 0 or len(complex_always) > 0

            # 检查数据流特征
            # 1. 多级数据处理
            sequential_blocks = re.findall(r'always\s*@\s*\([^)]*posedge[^)]*\)[\s\S]*?end', clean_code)
            has_multi_stage_processing = len(sequential_blocks) > 1

            # 2. 可能的数据依赖（检查寄存器间引用）
            reg_declarations = re.findall(r'reg\s+(?:\[\s*\d+\s*:\s*\d+\s*\]\s*)?(\w+)', clean_code)
            reg_dependencies = 0

            for reg in reg_declarations:
                for other_reg in reg_declarations:
                    if reg != other_reg and re.search(rf'{reg}[\s\[\]].*{other_reg}', clean_code):
                        reg_dependencies += 1

            # 存储检测到的特征
            self.code_features = {
                "has_pipeline": pipeline_features["has_pipeline"],
                "pipeline_stages": pipeline_features["stage_count"],
                "max_stage": pipeline_features["max_stage"],
                "complex_datapath": has_complex_datapath,
                "multi_stage_processing": has_multi_stage_processing,
                "reg_dependencies": reg_dependencies
            }

            self.logger.info(f"流水线特征检测: {self.code_features}")

            # 判断是否适用于流水线变换
            # 如果已有流水线或有复杂数据路径，则适用
            return pipeline_features["has_pipeline"] or has_complex_datapath or has_multi_stage_processing

        except Exception as e:
            self.logger.error(f"检查流水线适用性时出错: {str(e)}")
            return False

    def get_prompt(self, code):
        """为流水线变换生成提示"""
        # 检测现有流水线结构
        pipeline_structure = self._detect_pipeline_structure(code)
        # 选择流水线变换策略
        pipeline_strategy = self._select_pipeline_strategy(pipeline_structure)

        return f"""
        你是一个专业的Verilog流水线架构设计专家。请对下面的Verilog代码应用{pipeline_strategy['name']}，
        以优化其性能、资源使用效率或延迟特性。

        变换目标：{pipeline_strategy['goal']}

        设计策略：
        {pipeline_strategy['strategy']}

        技术要点：
        {pipeline_strategy['technical_details']}

        请确保：
        1. 完整保持原代码的核心功能，但调整其流水线架构
        2. {pipeline_strategy['implementation_notes']}
        3. 流水线控制逻辑正确，能够正确处理复位和启动情况
        4. 所有寄存器命名遵循清晰的流水线级别命名规范（如signal_stage1, signal_stage2等）
        5. 数据依赖关系正确处理，不引入数据冒险或竞争
        6. 代码中添加适当注释，特别是关于流水线级别和数据流的说明

        原始代码:
        ```verilog
        {code}
        ```

        请返回完整的优化后的Verilog代码。不需要解释，只需要返回代码。
        """

    def _detect_pipeline_structure(self, code):
        """检测代码中的流水线结构"""
        # 查找可能的流水线寄存器模式
        pipeline_regs = re.findall(r'reg\s+(?:\[\s*\d+\s*:\s*\d+\s*\]\s*)?(\w+_stage\d+|\w+_pipe\d+|\w+_s\d+|\w+_p\d+)',
                                   code)
        stage_numbers = []

        for reg in pipeline_regs:
            # 尝试多种常见的流水线命名模式
            match = re.search(r'(?:stage|pipe|s|p)(\d+)', reg)
            if match:
                stage_numbers.append(int(match.group(1)))

        # 查找阶段命名约定（如 parameter STAGE1=1, STAGE2=2 等）
        stage_params = re.findall(r'parameter\s+STAGE\d+\s*=', code)

        # 查找指示流水线深度的参数
        pipeline_depth_param = re.search(r'parameter\s+(\w*PIPE\w*_DEPTH|\w*PIPELINE\w*_STAGES)\s*=\s*(\d+)', code)
        explicit_depth = int(pipeline_depth_param.group(2)) if pipeline_depth_param else 0

        return {
            'has_pipeline': len(stage_numbers) > 0 or len(stage_params) > 0 or explicit_depth > 0,
            'stages': sorted(list(set(stage_numbers))) if stage_numbers else [],
            'stage_count': len(set(stage_numbers)) if stage_numbers else explicit_depth,
            'max_stage': max(stage_numbers) if stage_numbers else explicit_depth,
            'explicit_depth': explicit_depth
        }

    def _select_pipeline_strategy(self, pipeline_structure):
        """根据代码特征选择流水线变换策略"""
        has_pipeline = pipeline_structure["has_pipeline"]
        stage_count = pipeline_structure["stage_count"]
        complex_datapath = self.code_features.get("complex_datapath", False)

        strategies = [
            {
                "name": "流水线架构转换",
                "weight": 5 if not has_pipeline and complex_datapath else 1,
                "goal": "将非流水线设计转换为流水线架构，提高吞吐量",
                "strategy": """
                将设计转换为流水线架构，主要步骤包括：
                1. 分析数据路径，识别可以分段的计算阶段
                2. 在合适位置插入流水线寄存器，将单周期计算分割成多级
                3. 添加必要的流水线控制逻辑（例如valid/ready信号）
                4. 确保所有数据和控制信号正确地穿过流水线
                """,
                "technical_details": """
                1. 将组合逻辑按功能和计算复杂度分段，尽量使各级计算负载均衡
                2. 每级之间添加寄存器，存储中间结果
                3. 创建控制信号链（如valid_stage1, valid_stage2等）传递有效信号
                4. 添加流水线启动和刷新（flush）逻辑
                5. 考虑数据依赖，必要时实现前递（forwarding）机制
                """,
                "implementation_notes": "重点是将原本的单周期或非流水线设计重构为合理的流水线架构，增加吞吐量"
            },
            {
                "name": "流水线深度调整",
                "weight": 5 if has_pipeline else 1,
                "goal": f"{'增加' if stage_count < 3 else '减少'}流水线级数，{'提高最大工作频率' if stage_count < 3 else '优化资源使用和延迟'}",
                "strategy": f"""
                {'增加流水线深度' if stage_count < 3 else '减少流水线深度'}，主要步骤包括：
                1. 分析当前流水线的各级计算复杂度
                2. {'识别计算复杂度高的级别，进一步拆分' if stage_count < 3 else '识别计算复杂度低的相邻级别，合并'}
                3. 调整流水线控制逻辑以适应新的级数
                4. 更新所有相关的时序和控制信号
                """,
                "technical_details": f"""
                1. {'将复杂度高的流水线级拆分为多个级别' if stage_count < 3 else '将复杂度低的相邻流水线级合并'}
                2. {'确保拆分后各级计算负载平衡' if stage_count < 3 else '确保合并后不超过时序约束'}
                3. 调整所有流水线控制逻辑
                4. 更新所有阶段指示器和控制信号
                5. 保持整体功能和数据流的正确性
                """,
                "implementation_notes": f"重点是{'增加' if stage_count < 3 else '减少'}流水线级数，{'提高时钟频率' if stage_count < 3 else '减少延迟和资源使用'}"
            }
        ]

        # 根据权重随机选择一个流水线策略
        weights = [s["weight"] for s in strategies]
        selected_strategy = random.choices(strategies, weights=weights, k=1)[0]

        self.logger.info(f"选择的流水线变换策略: {selected_strategy['name']}")
        return selected_strategy
