import sys
import os
import argparse
from core import HVMSFramework


def main():
    """主程序入口"""
    # 解析命令行参数
    parser = argparse.ArgumentParser(description='HVMS: 同源异构Verilog变异搜索')
    parser.add_argument('--config', default="D:\\Python Project\\HVMS\\config\\config.yaml",
                        help='配置文件路径 (默认: %(default)s)')
    parser.add_argument('--variations', type=int, help='每个种子代码的目标变异数量 (可选，默认使用配置文件值)')
    parser.add_argument('--verbose', action='store_true', help='启用详细日志输出')
    parser.add_argument('--reset-progress', action='store_true', help='重置进度，从头开始处理所有种子文件')

    args = parser.parse_args()

    # 验证配置文件路径
    config_path = os.path.abspath(args.config)
    if not os.path.exists(config_path):
        print(f"错误: 配置文件 '{config_path}' 不存在", file=sys.stderr)
        return 1

    print(f"使用配置文件: {config_path}")

    try:
        # 创建HVMS框架实例
        hvms = HVMSFramework(config_path=config_path)

        # 如果需要重置进度
        if args.reset_progress:
            progress_file = os.path.join(os.path.dirname(hvms.output_verilog_path), "progress.json")
            if os.path.exists(progress_file):
                try:
                    os.remove(progress_file)
                    print(f"进度文件已删除: {progress_file}")
                except Exception as e:
                    print(f"警告: 无法删除进度文件: {str(e)}", file=sys.stderr)
            else:
                print("未找到进度文件，无需重置")

        # 运行HVMS框架
        stats = hvms.run(num_variations_per_seed=args.variations)

        # 打印结果统计
        print("\n=== HVMS运行结果 ===")
        print(f"处理了 {stats['processed_seeds']}/{stats['total_seeds']} 个种子文件")
        print(f"生成了 {stats['total_variations']} 个有价值的变异")
        print(f"总运行时间: {stats['duration']:.2f} 秒")

        return 0

    except Exception as e:
        print(f"错误: {str(e)}", file=sys.stderr)
        import traceback
        print(traceback.format_exc(), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())