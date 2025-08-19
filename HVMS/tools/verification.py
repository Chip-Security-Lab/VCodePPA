import os
import re
import string
import tempfile
import subprocess
import logging
import random
from pathlib import Path


class VerilogVerifier:
    """Verilog代码功能验证工具"""

    def __init__(self, logger=None):
        """
        初始化验证工具

        Args:
            logger: 日志记录器
        """
        self.logger = logger or logging.getLogger(self.__class__.__name__)

    def verify_equivalence(self, original_code, transformed_code, transform_count=None):
        """验证两段代码的功能等价性"""
        # 提取模块名
        orig_module = self._extract_module_name(original_code)

        if not orig_module:
            self.logger.error("无法提取原始代码的模块名")
            return False

        # 确定变换后的模块名
        if transform_count is not None:
            # 使用固定格式的迭代计数作为后缀
            new_trans_module = f"{orig_module}_iter{transform_count}"

            # 添加随机字符串以确保唯一性，但保留迭代计数前缀
            import string
            unique_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
            unique_id = f"iter{transform_count}_{unique_suffix}"
        else:
            # 如果没有提供计数，只使用随机后缀
            import string
            unique_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
            new_trans_module = f"{orig_module}_{unique_suffix}"
            unique_id = unique_suffix

        # 使用一致的命名约定
        self.logger.info(f"准备重命名模块: {orig_module} -> {new_trans_module}")

        # 修改变换后代码中的模块名，传递完整的目标模块名，而不是分开的后缀
        transformed_code_renamed = self._rename_module_in_code(transformed_code, new_trans_module, unique_id)

        try:
            # 创建临时工作目录
            temp_dir = tempfile.mkdtemp(prefix=f"verilog_verify_{unique_suffix}_")
            self.logger.info(f"创建临时工作目录: {temp_dir}")

            # 保存代码到临时文件
            orig_file = os.path.join(temp_dir, f"{orig_module}_original.v")
            trans_file = os.path.join(temp_dir, f"{new_trans_module}.v")

            with open(orig_file, 'w', encoding='utf-8') as f:
                f.write(original_code)

            with open(trans_file, 'w', encoding='utf-8') as f:
                f.write(transformed_code_renamed)

            # 检查变换后文件中是否包含正确的模块名
            with open(trans_file, 'r', encoding='utf-8') as f:
                saved_code = f.read()
                if f"module {new_trans_module}" not in saved_code:
                    self.logger.error(f"保存的文件中找不到正确的模块名: {new_trans_module}")
                    self.logger.debug(f"文件内容前100字符: {saved_code[:100]}")
                    return False

            # 生成测试台
            tb_file = self._generate_testbench(temp_dir, orig_module, new_trans_module)

            # 检查测试台文件
            with open(tb_file, 'r', encoding='utf-8') as f:
                tb_content = f.read()
                if f"{new_trans_module} transformed_inst" not in tb_content:
                    self.logger.error(f"测试台中找不到变换后的模块名: {new_trans_module}")
                    return False

            # 使用iverilog运行仿真前打印调试信息
            self.logger.info(f"原始模块: {orig_module}, 变换后模块: {new_trans_module}")
            self.logger.info(f"文件列表: {os.listdir(temp_dir)}")

            # 使用iverilog运行仿真
            result = self._run_simulation(temp_dir, [orig_file, trans_file, tb_file])

            # 如果仿真失败，保留临时目录用于调试
            if result is None:
                self.logger.warning(f"保留临时目录用于调试: {temp_dir}")
                return False

            # 解析结果
            is_equivalent = self._parse_simulation_result(result)

            # 清理临时文件（成功时）
            if is_equivalent:
                try:
                    import shutil
                    shutil.rmtree(temp_dir)
                except Exception as e:
                    self.logger.warning(f"清理临时文件失败: {str(e)}")

            return is_equivalent

        except Exception as e:
            self.logger.error(f"验证等价性时出错: {str(e)}")
            import traceback
            self.logger.error(traceback.format_exc())
            return False

    def _extract_module_name(self, code):
        """从Verilog代码中提取模块名"""
        match = re.search(r'module\s+(\w+)', code)
        if match:
            return match.group(1)
        return None

    def _extract_ports(self, code):
        """从Verilog代码中提取端口信息"""
        # 提取模块声明
        module_match = re.search(r'module\s+\w+\s*\((.*?)\);', code, re.DOTALL)
        if not module_match:
            return []

        port_text = module_match.group(1)
        port_list = [p.strip() for p in port_text.split(',')]

        ports = []
        # 在模块定义和endmodule之间查找端口定义
        module_body = re.search(r'module.*?endmodule', code, re.DOTALL)
        if module_body:
            body = module_body.group(0)

            for port in port_list:
                # 查找输入端口
                input_match = re.search(r'input\s+(?:wire|reg)?\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*' + port + r'\b',
                                        body)
                if input_match:
                    width = None
                    if input_match.group(1) and input_match.group(2):
                        width = (int(input_match.group(1)), int(input_match.group(2)))
                    ports.append(('input', port, width))
                    continue

                # 查找输出端口
                output_match = re.search(r'output\s+(?:wire|reg)?\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*' + port + r'\b',
                                         body)
                if output_match:
                    width = None
                    if output_match.group(1) and output_match.group(2):
                        width = (int(output_match.group(1)), int(output_match.group(2)))
                    ports.append(('output', port, width))
                    continue

                # 查找双向端口
                inout_match = re.search(r'inout\s+(?:wire|reg)?\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*' + port + r'\b',
                                        body)
                if inout_match:
                    width = None
                    if inout_match.group(1) and inout_match.group(2):
                        width = (int(inout_match.group(1)), int(inout_match.group(2)))
                    ports.append(('inout', port, width))

        return ports

    def _generate_testbench(self, work_dir, orig_module, trans_module):
        """
        生成用于等价性验证的测试台

        Args:
            work_dir: 工作目录
            orig_module: 原始模块名
            trans_module: 变换后的模块名

        Returns:
            str: 测试台文件路径
        """
        # 读取原始模块以提取端口信息
        orig_file = os.path.join(work_dir, f"{orig_module}_original.v")
        with open(orig_file, 'r', encoding='utf-8') as f:
            orig_code = f.read()

        ports = self._extract_ports(orig_code)

        # 生成测试台代码
        tb_code = f"""
    `timescale 1ns/1ps

    module tb_equivalence();

    // 时钟和复位
    reg clk;
    reg rst_n;

    // 初始化时钟和复位
    initial begin
        clk = 0;
        rst_n = 0;
        #100 rst_n = 1;
    end

    // 生成时钟
    always #5 clk = ~clk;

    """

        # 声明用于测试的信号
        for direction, name, width in ports:
            if direction == 'input':
                if width:
                    tb_code += f"reg [{width[0]}:{width[1]}] {name};\n"
                else:
                    tb_code += f"reg {name};\n"
            elif direction == 'output':
                if width:
                    tb_code += f"wire [{width[0]}:{width[1]}] {name}_orig, {name}_trans;\n"
                else:
                    tb_code += f"wire {name}_orig, {name}_trans;\n"
            elif direction == 'inout':
                if width:
                    tb_code += f"wire [{width[0]}:{width[1]}] {name};\n"
                    tb_code += f"wire [{width[0]}:{width[1]}] {name}_orig, {name}_trans;\n"
                else:
                    tb_code += f"wire {name};\n"
                    tb_code += f"wire {name}_orig, {name}_trans;\n"

        # 实例化原始模块
        tb_code += f"\n// 原始模块实例\n{orig_module} original_inst (\n"
        instance_ports = []
        for direction, name, _ in ports:
            if direction == 'input':
                instance_ports.append(f".{name}({name})")
            elif direction == 'output':
                instance_ports.append(f".{name}({name}_orig)")
            elif direction == 'inout':
                instance_ports.append(f".{name}({name}_orig)")
        tb_code += ',\n'.join(instance_ports)
        tb_code += "\n);\n"

        # 实例化变换后的模块
        tb_code += f"\n// 变换后的模块实例\n{trans_module} transformed_inst (\n"
        instance_ports = []
        for direction, name, _ in ports:
            if direction == 'input':
                instance_ports.append(f".{name}({name})")
            elif direction == 'output':
                instance_ports.append(f".{name}({name}_trans)")
            elif direction == 'inout':
                instance_ports.append(f".{name}({name}_trans)")
        tb_code += ',\n'.join(instance_ports)
        tb_code += "\n);\n"

        # 添加输入激励生成
        tb_code += """
    // 随机激励生成
    initial begin
        // 等待复位完成
        @(posedge rst_n);

        // 进行100个随机测试向量
        repeat(100) begin
            // 对所有输入应用随机值
    """

        for direction, name, width in ports:
            if direction == 'input':
                if width:
                    bit_width = width[0] - width[1] + 1
                    tb_code += f"        {name} = $random & {{{bit_width}{{1'b1}}}};\n"
                else:
                    tb_code += f"        {name} = $random & 1'b1;\n"

        tb_code += """
            // 等待一个时钟周期让结果稳定
            @(posedge clk);
            #1;

            // 比较输出
    """

        for direction, name, width in ports:
            if direction == 'output':
                if width:
                    tb_code += f"""
            if ({name}_orig !== {name}_trans) begin
                $display("不匹配: 时间 %t, 信号 {name}, 原始值 %h, 变换值 %h", $time, {name}_orig, {name}_trans);
                $finish;
            end
    """
                else:
                    tb_code += f"""
            if ({name}_orig !== {name}_trans) begin
                $display("不匹配: 时间 %t, 信号 {name}, 原始值 %b, 变换值 %b", $time, {name}_orig, {name}_trans);
                $finish;
            end
    """

        tb_code += """
        end

        // 所有测试通过
        $display("等价性验证通过: 所有输出匹配");
        $finish;
    end

    // 设置最大仿真时间
    initial begin
        #10000 $display("仿真超时");
        $finish;
    end

    endmodule
    """

        # 写入测试台文件
        tb_file = os.path.join(work_dir, "tb_equivalence.v")
        with open(tb_file, 'w', encoding='utf-8') as f:
            f.write(tb_code)

        return tb_file

    def _run_simulation(self, work_dir, verilog_files):
        """
        使用iverilog运行仿真

        Args:
            work_dir: 工作目录
            verilog_files: Verilog文件路径列表

        Returns:
            str: 仿真输出
        """
        # 检查是否安装了iverilog
        if not self._has_iverilog():
            self.logger.error("未找到iverilog，无法执行仿真")
            return None

        try:
            # 构建命令
            vvp_file = os.path.join(work_dir, "tb_sim.vvp")
            verilog_files_str = ' '.join([f'"{f}"' for f in verilog_files])

            compile_cmd = f'iverilog -o "{vvp_file}" {verilog_files_str}'
            run_cmd = f'vvp "{vvp_file}"'

            self.logger.info(f"编译命令: {compile_cmd}")

            # 编译 - 使用特定编码
            compile_result = subprocess.run(
                compile_cmd,
                shell=True,
                capture_output=True,
                text=True,
                encoding='utf-8',  # 指定编码为UTF-8
                errors='replace',  # 替换无法解码的字符
                cwd=work_dir
            )

            if compile_result.returncode != 0:
                self.logger.error(f"编译失败: {compile_result.stderr}")
                return None

            self.logger.info("编译成功，运行仿真")

            # 运行仿真 - 使用特定编码
            sim_result = subprocess.run(
                run_cmd,
                shell=True,
                capture_output=True,
                text=True,
                encoding='utf-8',  # 指定编码为UTF-8
                errors='replace',  # 替换无法解码的字符
                cwd=work_dir
            )

            # 检查返回码
            if sim_result.returncode != 0:
                self.logger.error(f"仿真失败，返回码: {sim_result.returncode}")

            # 安全合并输出和错误
            stdout = sim_result.stdout if sim_result.stdout else ""
            stderr = sim_result.stderr if sim_result.stderr else ""
            output = stdout + "\n" + stderr

            self.logger.info(f"仿真输出: {output}")

            return output

        except Exception as e:
            self.logger.error(f"运行仿真时出错: {str(e)}")
            import traceback
            self.logger.error(traceback.format_exc())  # 打印完整堆栈跟踪
            return None

    def _parse_simulation_result(self, output):
        """
        解析仿真输出，判断是否等价

        Args:
            output: 仿真输出

        Returns:
            bool: 是否等价
        """
        if output is None:
            self.logger.error("仿真输出为空，无法解析")
            return False

        # 检查是否有不匹配的信息
        if "不匹配" in output:
            return False

        # 检查是否有通过的信息
        if "等价性验证通过" in output:
            return True

        return False

    def _has_iverilog(self):
        """检查系统中是否安装了iverilog"""
        try:
            # 获取iverilog的完整路径
            import shutil
            iverilog_path = shutil.which("iverilog")

            if iverilog_path:
                self.logger.info(f"找到iverilog: {iverilog_path}")
                return True
            else:
                self.logger.error("未找到iverilog的完整路径")
                return False
        except Exception as e:
            self.logger.error(f"检查iverilog失败: {str(e)}")
            return False

    def _rename_module_in_code(self, code, new_module_name, unique_id):
        """
        修改Verilog代码中的所有模块名

        Args:
            code: 原始Verilog代码
            new_module_name: 新的模块名（完整名称，不需要再拼接）
            unique_id: 唯一标识符（用于内部模块）
        """
        # 提取所有模块定义
        module_pattern = r'module\s+(\w+)\s*(?:\(|#|;)'
        all_modules = re.findall(module_pattern, code)
        all_modules = [m for m in all_modules if m != "module"]

        # 防止空模块列表
        if not all_modules:
            self.logger.warning("未能找到任何模块名，返回原始代码")
            return code

        # 去除重复模块名
        unique_modules = list(dict.fromkeys(all_modules))

        # 为每个模块创建新名称
        module_mapping = {}
        for i, module_name in enumerate(unique_modules):
            if i == 0:  # 主模块使用完整的传入名称
                module_mapping[module_name] = new_module_name
            else:  # 子模块使用唯一ID
                module_mapping[module_name] = f"{module_name}_{unique_id}"

        # 用新名称替换所有模块定义
        modified_code = code
        for old_name, new_name in module_mapping.items():
            # 1. 替换模块声明 - 更严格的匹配
            modified_code = re.sub(
                r'(module\s+)' + re.escape(old_name) + r'(\s*(?:\(|#|;))',
                f'\\1{new_name}\\2',
                modified_code
            )

            # 2. 替换模块实例化
            modified_code = re.sub(
                r'(\s|\()' + re.escape(old_name) + r'(\s+\w+\s*\()',
                f'\\1{new_name}\\2',
                modified_code
            )

            # 3. 替换模块结束注释
            modified_code = re.sub(
                r'(endmodule\s*(?://\s*)?)' + re.escape(old_name) + r'(\s|$)',
                f'\\1{new_name}\\2',
                modified_code
            )

            # 4. 处理独立的endmodule (没有注释的情况)
            endmodule_count = modified_code.count('endmodule')
            module_count = len(re.findall(r'module\s+', modified_code))

            if endmodule_count == module_count and not re.search(r'endmodule\s*//.*' + re.escape(new_name),
                                                                 modified_code):
                # 找到模块对应的endmodule
                module_parts = modified_code.split(f"module {new_name}")
                if len(module_parts) > 1:
                    end_part = module_parts[1]
                    first_endmodule = end_part.find("endmodule")
                    if first_endmodule >= 0:
                        # 在这个endmodule后添加注释
                        end_pos = module_parts[1].find("endmodule") + len("endmodule")
                        modified_code = module_parts[0] + f"module {new_name}" + \
                                        module_parts[1][:end_pos] + f" // {new_name}" + \
                                        module_parts[1][end_pos:]

        self.logger.info(f"模块重命名: {module_mapping}")

        # 最后检查是否有重复模块声明
        final_modules = re.findall(r'module\s+(\w+)', modified_code)
        if len(final_modules) != len(set(final_modules)):
            self.logger.warning(f"重命名后仍存在重复模块名: {[m for m in final_modules if final_modules.count(m) > 1]}")

        return modified_code
