import os
import re
import tempfile
import subprocess
import logging
import time
import shutil
from pathlib import Path


class VivadoTool:
    """Vivado工具接口，用于获取Verilog代码的PPA指标"""

    def __init__(self, vivado_path, tcl_script, fpga_part, logger=None):
        """
        初始化Vivado工具接口

        Args:
            vivado_path: Vivado可执行文件路径
            tcl_script: 用于综合和实现的TCL脚本路径
            fpga_part: 目标FPGA型号
            logger: 日志记录器
        """
        self.vivado_path = vivado_path
        self.tcl_script = tcl_script
        self.fpga_part = fpga_part
        self.logger = logger or logging.getLogger(self.__class__.__name__)

    def get_ppa_metrics(self, code, module_name=None):
        """
        使用Vivado获取Verilog代码的PPA指标

        Args:
            code: Verilog代码
            module_name: 模块名称 (可选，如果不提供则会从代码中提取)

        Returns:
            dict: PPA指标
        """
        try:
            # 确定模块名
            if not module_name:
                module_match = re.search(r'module\s+(\w+)', code)
                if module_match:
                    module_name = module_match.group(1)
                else:
                    self.logger.error("无法从代码中提取模块名称")
                    return None

            # 创建临时工作目录
            temp_dir = tempfile.mkdtemp(prefix="vivado_ppa_")
            self.logger.info(f"创建临时工作目录: {temp_dir}")

            # 保存代码到临时文件
            verilog_file = os.path.join(temp_dir, f"{module_name}.v")
            with open(verilog_file, 'w', encoding='utf-8') as f:
                f.write(code)

            # 运行Vivado
            result = self._run_vivado(verilog_file, module_name, temp_dir)

            if not result:
                self.logger.error("Vivado执行失败")
                return None

            # 解析PPA报告
            ppa_metrics = self._parse_ppa_report(os.path.join(temp_dir, f"{module_name}_ppa_report.txt"))

            # 清理临时文件
            if os.path.exists(temp_dir):
                try:
                    shutil.rmtree(temp_dir)
                except Exception as e:
                    self.logger.warning(f"清理临时目录失败: {str(e)}")

            return ppa_metrics

        except Exception as e:
            self.logger.error(f"获取PPA指标失败: {str(e)}")
            import traceback
            self.logger.error(traceback.format_exc())
            # 尝试清理临时文件
            if 'temp_dir' in locals() and os.path.exists(temp_dir):
                try:
                    shutil.rmtree(temp_dir)
                except:
                    pass
            return None

    def _run_vivado(self, verilog_file, module_name, work_dir):
        """
        运行Vivado

        Args:
            verilog_file: Verilog文件路径
            module_name: 模块名
            work_dir: 工作目录

        Returns:
            bool: 是否成功运行
        """
        try:
            # 构建命令
            cmd = f'"{self.vivado_path}" -mode batch -nojournal -nolog -source "{self.tcl_script}" -tclargs "{verilog_file}" "{module_name}" "{self.fpga_part}" "{work_dir}"'

            # 创建日志文件
            log_file = os.path.join(work_dir, "vivado.log")
            self.logger.info(f"运行Vivado命令: {cmd}")

            # 运行Vivado
            with open(log_file, 'w') as f:
                start_time = time.time()
                process = subprocess.Popen(
                    cmd,
                    shell=True,
                    stdout=f,
                    stderr=subprocess.STDOUT,
                    cwd=work_dir
                )

            # 等待完成，最多等待30分钟
            timeout_seconds = 1800
            completed = False

            while not completed and (time.time() - start_time) < timeout_seconds:
                # 检查进程是否还在运行
                if process.poll() is not None:
                    completed = True
                else:
                    # 避免CPU过载
                    time.sleep(5)

            # 如果超时，强制终止进程
            if not completed:
                self.logger.warning(f"Vivado执行超时（{timeout_seconds}秒），强制终止")
                process.terminate()
                # 给进程一些时间来终止
                time.sleep(5)
                # 如果仍然在运行，强制终止
                if process.poll() is None:
                    process.kill()
                return False

            # 检查返回代码
            if process.returncode != 0:
                self.logger.error(f"Vivado运行失败，返回代码: {process.returncode}")
                return False

            # 检查是否生成了PPA报告
            ppa_report = os.path.join(work_dir, f"{module_name}_ppa_report.txt")
            if not os.path.exists(ppa_report):
                self.logger.error(f"PPA报告文件不存在: {ppa_report}")
                return False

            elapsed_time = time.time() - start_time
            self.logger.info(f"Vivado执行完成，耗时: {elapsed_time:.2f}秒")
            return True

        except Exception as e:
            self.logger.error(f"运行Vivado时出错: {str(e)}")
            import traceback
            self.logger.error(traceback.format_exc())
            return False

    def _parse_ppa_report(self, report_file):
        """
        解析PPA报告文件

        Args:
            report_file: PPA报告文件路径

        Returns:
            dict: PPA指标
        """
        ppa_metrics = {
            'lut': 0,
            'ff': 0,
            'io': 0,
            'cell_count': 0,  # 替换原有的utilization
            'max_freq': 0.0,
            'critical_path_delay': 0.0,
            'total_power': 0.0,
        }

        try:
            with open(report_file, 'r') as f:
                content = f.read()

                # 解析面积指标
                lut_match = re.search(r'LUT (?:Count|Usage):\s*(\d+)', content)
                if lut_match:
                    ppa_metrics['lut'] = int(lut_match.group(1))

                ff_match = re.search(r'FF (?:Count|Usage):\s*(\d+)', content)
                if ff_match:
                    ppa_metrics['ff'] = int(ff_match.group(1))

                io_match = re.search(r'IO (?:Count|Usage):\s*(\d+)', content)
                if io_match:
                    ppa_metrics['io'] = int(io_match.group(1))

                # 新增: 提取Cell数量
                cell_match = re.search(r'Cell Count:\s*(\d+)', content)
                if cell_match:
                    ppa_metrics['cell_count'] = int(cell_match.group(1))

                # 解析性能指标
                freq_match = re.search(r'Maximum (?:Clock )?Frequency:\s*([\d\.]+)\s*MHz', content)
                if freq_match:
                    ppa_metrics['max_freq'] = float(freq_match.group(1))

                delay_match = re.search(r'(?:Longest Path|Critical Path) Delay:\s*([\d\.]+)\s*ns', content)
                if delay_match:
                    ppa_metrics['critical_path_delay'] = float(delay_match.group(1))

                # 解析功耗指标 - 只保留总功耗
                total_power_match = re.search(r'Total Power(?: Consumption)?:\s*([\d\.]+)\s*W', content)
                if total_power_match:
                    ppa_metrics['total_power'] = float(total_power_match.group(1))

            self.logger.info(f"解析PPA指标: {ppa_metrics}")
            return ppa_metrics

        except Exception as e:
            self.logger.error(f"解析PPA报告时出错: {str(e)}")
            import traceback
            self.logger.error(traceback.format_exc())
            return ppa_metrics

    def save_ppa_report(self, metrics, file_path, module_name=None):
        """
        保存PPA指标报告

        Args:
            metrics: PPA指标
            file_path: 输出文件路径
            module_name: 模块名称（可选）

        Returns:
            bool: 是否成功保存
        """
        try:
            # 确保目录存在
            os.makedirs(os.path.dirname(file_path), exist_ok=True)

            # 提取基本文件名（不含路径和扩展名）
            base_filename = os.path.splitext(os.path.basename(file_path))[0]

            # 如果没有提供模块名，从文件名中提取
            if not module_name:
                module_name = base_filename.replace("_report", "")

            # 写入PPA报告
            with open(file_path, 'w') as f:
                f.write(f"PPA Report for {module_name}.v (Module: {module_name})\n")
                f.write(f"==========================================\n\n")

                f.write(f"FPGA Device: {self.fpga_part} (UltraScale+ 16nm Technology)\n\n")

                f.write("AREA METRICS:\n")
                f.write("------------\n")
                f.write(f"LUT Count: {metrics.get('lut', 'N/A')}\n")
                f.write(f"FF Count: {metrics.get('ff', 'N/A')}\n")
                f.write(f"IO Count: {metrics.get('io', 'N/A')}\n")
                f.write(f"Cell Count: {metrics.get('cell_count', 'N/A')}\n\n")

                f.write("PERFORMANCE METRICS:\n")
                f.write("-------------------\n")

                # 处理最大频率
                max_freq = metrics.get('max_freq', 0)
                if max_freq > 0:
                    f.write(f"Maximum Clock Frequency: {max_freq:.2f} MHz\n")
                else:
                    f.write("Maximum Clock Frequency: N/A (Combinational logic)\n")

                f.write(f"Longest Path Delay: {metrics.get('critical_path_delay', 'N/A'):.3f} ns\n\n")

                f.write("POWER METRICS:\n")
                f.write("-------------\n")
                f.write(f"Total Power Consumption: {metrics.get('total_power', 'N/A'):.3f} W\n")

            self.logger.info(f"PPA报告已保存到: {file_path}")
            return True

        except Exception as e:
            self.logger.error(f"保存PPA报告时出错: {str(e)}")
            import traceback
            self.logger.error(traceback.format_exc())
            return False
