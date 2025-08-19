import json
import os
import logging
import yaml
import time
import re
from pathlib import Path
from multiprocessing import cpu_count
from .parallel_mcts import ParallelMCTSSearch  # 导入并行MCTS
from utils import VerilogParser, setup_logger


class HVMSFramework:
    """同源异构Verilog变异搜索(HVMS)框架"""

    def __init__(self, config_path=None):
        """
        初始化HVMS框架

        Args:
            config_path: 配置文件路径
        """
        # 设置初始日志记录器
        import logging
        self.logger = logging.getLogger("hvms_init")
        if not self.logger.handlers:
            handler = logging.StreamHandler()
            handler.setFormatter(logging.Formatter('[%(asctime)s] [%(levelname)s] - %(message)s'))
            self.logger.addHandler(handler)
            self.logger.setLevel(logging.INFO)

        self.logger.info(f"初始化HVMS框架，配置文件: {config_path}")

        # 加载配置
        self.config = self._load_config(config_path)

        # 设置正式日志记录器
        from utils import setup_logger
        self.logger = setup_logger(
            name="hvms",
            level=getattr(logging, self.config['logging']['level']),
            log_file=self.config['logging']['file']
        )

        self.logger.info("HVMS框架初始化完成")

        # 导入必要的组件
        from agents import ClaudeAgent
        from transformers import TransformerManager
        from tools import VivadoTool, VerilogVerifier

        # 初始化Claude Agent
        self.agent = ClaudeAgent(
            api_key=self.config['agent']['api_key'],
            model=self.config['agent']['model'],
            timeout=self.config['agent']['timeout'],
            max_retries=self.config['agent']['max_retries'],
            logger=self.logger
        )

        # 初始化变换器管理器
        self.transformer_manager = TransformerManager(
            agent=self.agent,
            logger=self.logger
        )

        # 初始化Vivado工具
        self.vivado_tool = VivadoTool(
            vivado_path=self.config['vivado']['path'],
            tcl_script=self.config['vivado']['tcl_script'],
            fpga_part=self.config['vivado']['fpga_part'],
            logger=self.logger
        )

        # 初始化验证工具
        self.verifier = VerilogVerifier(
            logger=self.logger
        )

        # 初始化路径
        self.seed_verilog_path = self.config['paths']['seed_verilog']
        self.seed_ppa_path = self.config['paths']['seed_ppa']
        self.output_verilog_path = self.config['paths']['output_verilog']
        self.output_ppa_path = self.config['paths']['output_ppa']

        # 确保输出目录存在
        os.makedirs(self.output_verilog_path, exist_ok=True)
        os.makedirs(self.output_ppa_path, exist_ok=True)

        # 设置并行度
        self.num_workers = self.config['mcts'].get('num_workers', min(cpu_count(), 4))
        self.paths_per_batch = self.config['mcts'].get('paths_per_batch', 8)

        # 记录配置信息
        self.logger.info(f"种子数据集路径: {self.seed_verilog_path}")
        self.logger.info(f"种子PPA路径: {self.seed_ppa_path}")
        self.logger.info(f"输出代码路径: {self.output_verilog_path}")
        self.logger.info(f"输出PPA路径: {self.output_ppa_path}")
        self.logger.info(f"最大搜索深度: {self.config['mcts']['max_depth']}")
        self.logger.info(f"PPA变化阈值: {self.config['mcts']['ppa_threshold']}")
        self.logger.info(f"并行工作进程数: {self.num_workers}")
        self.logger.info(f"每批次探索路径数: {self.paths_per_batch}")

    def run(self, num_variations_per_seed=None):
        """
        运行HVMS框架，对种子数据集中的每个Verilog代码生成变体

        Args:
            num_variations_per_seed: 每个种子代码的目标变异数量 (可选，默认使用配置文件值)

        Returns:
            dict: 处理结果统计
        """
        # 如果没有指定参数，则使用配置文件中的值
        if num_variations_per_seed is None:
            num_variations_per_seed = self.config['mcts']['variations_per_seed']
            self.logger.info(f"使用配置文件中的变异数量: {num_variations_per_seed}")
        else:
            self.logger.info(f"使用传入的变异数量（覆盖配置文件）: {num_variations_per_seed}")

        self.logger.info(f"开始运行HVMS框架，目标每个种子生成{num_variations_per_seed}个变异")

        # 加载种子数据集
        seed_files = VerilogParser.scan_directory(self.seed_verilog_path)

        # 加载进度跟踪文件
        progress_file = os.path.join(os.path.dirname(self.output_verilog_path), "progress.json")
        processed_seeds = {}
        if os.path.exists(progress_file):
            try:
                with open(progress_file, 'r') as f:
                    processed_seeds = json.load(f)
                self.logger.info(f"加载进度文件，已处理 {len(processed_seeds)} 个种子文件")
            except Exception as e:
                self.logger.error(f"加载进度文件失败: {str(e)}")
                processed_seeds = {}

        # 过滤掉已处理的种子文件
        remaining_seeds = []
        for seed_file in seed_files:
            seed_basename = os.path.basename(seed_file)
            seed_name = os.path.splitext(seed_basename)[0]
            if seed_name not in processed_seeds:
                remaining_seeds.append(seed_file)

        self.logger.info(f"找到 {len(seed_files)} 个种子文件，其中 {len(remaining_seeds)} 个未处理")

        if not remaining_seeds:
            self.logger.info("所有种子文件已处理完毕，无需继续执行")
            # 返回空统计信息
            return {
                'total_seeds': len(seed_files),
                'processed_seeds': 0,
                'total_variations': 0,
                'start_time': time.time(),
                'end_time': time.time(),
                'duration': 0
            }

        # 统计信息
        stats = {
            'total_seeds': len(seed_files),
            'processed_seeds': 0,
            'total_variations': 0,
            'start_time': time.time()
        }

        # 处理每个剩余的种子文件
        for i, seed_file in enumerate(remaining_seeds):
            seed_basename = os.path.basename(seed_file)
            seed_name = os.path.splitext(seed_basename)[0]

            self.logger.info(f"处理种子文件 [{i + 1}/{len(remaining_seeds)}]: {seed_basename}")

            try:
                # 读取种子代码
                seed_code = VerilogParser.read_file(seed_file)

                # 获取种子代码的PPA指标
                seed_ppa = self._get_seed_ppa(seed_name)

                if not seed_ppa:
                    self.logger.warning(f"未找到种子 {seed_name} 的PPA数据，跳过")
                    continue

                # 创建并行MCTS搜索实例
                mcts = ParallelMCTSSearch(
                    seed_code=seed_code,
                    seed_ppa=seed_ppa,
                    transformer_manager=self.transformer_manager,
                    vivado_tool=self.vivado_tool,
                    verifier=self.verifier,
                    max_depth=self.config['mcts']['max_depth'],
                    ppa_threshold=self.config['mcts']['ppa_threshold'],
                    c_param=self.config['mcts']['c_param'],
                    max_workers=self.num_workers,
                    paths_per_batch=self.paths_per_batch,
                    logger=self.logger
                )

                # 运行MCTS搜索，获取变异代码
                variations = mcts.search(
                    target_count=num_variations_per_seed,
                    max_iterations=self.config['mcts']['max_iterations']
                )

                # 保存变异代码和PPA报告
                for j, (var_code, var_ppa) in enumerate(variations):
                    # 提取模块名
                    module_match = re.search(r'module\s+(\w+)', var_code)
                    if module_match:
                        module_name = module_match.group(1)
                    else:
                        module_name = f"{seed_name}_variant_{j + 1}"

                    # 构建文件名
                    var_name = f"{seed_name}_variant_{j + 1}"

                    # 保存变异代码
                    var_file = os.path.join(self.output_verilog_path, f"{var_name}.v")
                    VerilogParser.write_file(var_file, var_code)

                    # 保存PPA报告
                    ppa_file = os.path.join(self.output_ppa_path, f"{var_name}_report.txt")
                    self.vivado_tool.save_ppa_report(var_ppa, ppa_file, module_name)

                # 更新统计信息
                stats['processed_seeds'] += 1
                stats['total_variations'] += len(variations)

                self.logger.info(f"种子 {seed_name} 处理完成，生成了 {len(variations)} 个变异")

                # 更新进度文件
                processed_seeds[seed_name] = {
                    "processed_time": time.strftime("%Y-%m-%d %H:%M:%S"),
                    "variations_count": len(variations)
                }

                try:
                    with open(progress_file, 'w') as f:
                        json.dump(processed_seeds, f, indent=2)
                except Exception as e:
                    self.logger.error(f"保存进度文件失败: {str(e)}")

            except Exception as e:
                self.logger.error(f"处理种子 {seed_name} 时出错: {str(e)}")
                import traceback
                self.logger.error(traceback.format_exc())

        # 计算运行时间
        stats['end_time'] = time.time()
        stats['duration'] = stats['end_time'] - stats['start_time']

        # 记录最终统计信息
        self.logger.info("HVMS框架运行完成")
        self.logger.info(f"处理了 {stats['processed_seeds']}/{len(remaining_seeds)} 个种子文件")
        self.logger.info(f"生成了 {stats['total_variations']} 个有价值的变异")
        self.logger.info(f"总运行时间: {stats['duration']:.2f} 秒")

        return stats

    def _load_config(self, config_path):
        """
        加载配置文件

        Args:
            config_path: 配置文件路径

        Returns:
            dict: 配置字典
        """
        import os
        from multiprocessing import cpu_count
        import yaml

        # 默认配置
        default_config = {
            'agent': {
                'api_key': "sk-QH95zut9TmvlmV2QzY4jOqQ0qxKq1IWfKyuJkmeX8zigFPmW",
                'model': "[额度]claude-3-7-sonnet",
                'timeout': 60,
                'max_retries': 3
            },
            'mcts': {
                'max_depth': 3,
                'ppa_threshold': 0.2,
                'c_param': 1.414,
                'max_iterations': 1000,
                'variations_per_seed': 10,
                'num_workers': 4,
                'paths_per_batch': 8,
            },
            'paths': {
                'seed_verilog': "D:/tcl/verilog_code",
                'seed_ppa': "D:/tcl/PPA_report",
                'output_verilog': "D:/tcl/HVMS_code",
                'output_ppa': "D:/tcl/HVMS_report"
            },
            'vivado': {
                'path': "D:/Xilinx/Vivado/2018.3/bin/vivado.bat",
                'tcl_script': "D:/tcl/vivado_synth.tcl",
                'fpga_part': "xcku3p-ffva676-2-e"
            },
            'logging': {
                'level': "INFO",
                'file': "logs/hvms.log"
            }
        }

        # 如果提供了配置文件，则加载并合并
        if config_path:
            self.logger.info(f"尝试加载配置文件: {config_path}")
            if not os.path.exists(config_path):
                self.logger.error(f"配置文件不存在: {config_path}")
            else:
                try:
                    with open(config_path, 'r', encoding='utf-8') as f:
                        self.logger.info(f"成功打开配置文件")
                        user_config = yaml.safe_load(f)

                        if user_config:
                            self.logger.info(f"成功解析配置文件")
                            # 记录用户配置中的关键值
                            if 'mcts' in user_config:
                                mcts = user_config.get('mcts', {})
                                self.logger.info(f"用户配置 - MCTS参数: max_depth={mcts.get('max_depth')}, "
                                                 f"paths_per_batch={mcts.get('paths_per_batch')}, "
                                                 f"num_workers={mcts.get('num_workers')}")

                            # 使用完全替换的方式应用 MCTS 配置
                            if 'mcts' in user_config:
                                for key, value in user_config['mcts'].items():
                                    if key in default_config['mcts']:
                                        self.logger.info(f"更新MCTS配置: {key} = {value}")
                                        default_config['mcts'][key] = value

                            # 递归合并其他配置
                            self._merge_config_recursive(default_config, user_config)
                        else:
                            self.logger.error(f"配置文件为空或格式错误")
                except Exception as e:
                    self.logger.error(f"加载配置文件失败: {str(e)}")
                    import traceback
                    self.logger.error(traceback.format_exc())

        # 记录最终使用的关键配置
        self.logger.info(f"最终配置 - MCTS参数: max_depth={default_config['mcts']['max_depth']}, "
                         f"paths_per_batch={default_config['mcts']['paths_per_batch']}, "
                         f"num_workers={default_config['mcts']['num_workers']}")

        return default_config

    def _merge_config_recursive(self, base, update):
        """
        递归合并配置

        Args:
            base: 基础配置
            update: 更新配置
        """
        for key, value in update.items():
            if key in base:
                if isinstance(base[key], dict) and isinstance(value, dict):
                    # 递归合并字典
                    self._merge_config_recursive(base[key], value)
                else:
                    # 直接替换非字典值
                    self.logger.info(f"配置更新: {key} = {value}")
                    base[key] = value
            else:
                # 添加新键
                self.logger.info(f"配置添加: {key} = {value}")
                base[key] = value


    def _get_seed_ppa(self, seed_name):
        """
        获取种子代码的PPA指标

        Args:
            seed_name: 种子名称

        Returns:
            dict: PPA指标
        """
        # 尝试查找PPA报告文件
        ppa_file = os.path.join(self.seed_ppa_path, f"{seed_name}_report.txt")

        if not os.path.exists(ppa_file):
            self.logger.warning(f"PPA报告文件不存在: {ppa_file}")
            return None

        try:
            # 解析PPA报告
            return self.vivado_tool._parse_ppa_report(ppa_file)

        except Exception as e:
            self.logger.error(f"解析PPA报告时出错: {str(e)}")
            return None
