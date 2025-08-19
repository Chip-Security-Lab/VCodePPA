#!/usr/bin/env python
"""Verilog-PPA模型推理脚本"""
import os
import sys
import argparse
import json
import torch
from tqdm import tqdm
from transformers import AutoTokenizer

# 添加项目根目录到路径
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from inference.generation import VerilogPPAGenerator
from utils.logger import setup_logger
from utils.common import format_ppa_metrics, compare_ppa_metrics, save_json


def parse_args():
    parser = argparse.ArgumentParser(description="Verilog-PPA模型推理")
    parser.add_argument("--model_path", type=str, required=True, help="模型路径")
    parser.add_argument("--input", type=str, required=True,
                        help="输入文件路径(单个Verilog文件或包含多个代码的JSON文件)")
    parser.add_argument("--output_file", type=str, default="output/generated_codes.json", help="输出文件路径")
    parser.add_argument("--temperature", type=float, default=0.8, help="生成温度")
    parser.add_argument("--top_p", type=float, default=0.9, help="核采样概率")
    parser.add_argument("--max_length", type=int, default=2048, help="最大生成长度")
    parser.add_argument("--num_return_sequences", type=int, default=3, help="每个输入生成的序列数量")
    parser.add_argument("--predict_ppa", action="store_true", help="是否预测PPA指标")
    return parser.parse_args()


def main():
    """主函数"""
    # 解析命令行参数
    args = parse_args()

    # 设置日志
    logger = setup_logger("inference")

    # 创建输出目录
    os.makedirs(os.path.dirname(args.output_file), exist_ok=True)

    # 设置设备
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info(f"使用设备: {device}")

    # 创建生成器
    generator = VerilogPPAGenerator(args.model_path, device)
    logger.info(f"模型加载完成: {args.model_path}")

    # 加载输入数据
    input_codes = []
    reference_ppas = []

    if args.input.endswith(('.v', '.sv')):
        # 单个Verilog文件
        with open(args.input, 'r', encoding='utf-8') as f:
            input_codes.append({
                "code": f.read(),
                "file": os.path.basename(args.input)
            })
    elif args.input.endswith('.json'):
        # JSON文件包含多个代码
        with open(args.input, 'r', encoding='utf-8') as f:
            data = json.load(f)

        if isinstance(data, list):
            for item in data:
                if isinstance(item, dict) and "code" in item:
                    input_codes.append(item)
                    if "ppa" in item:
                        reference_ppas.append(item["ppa"])
        else:
            logger.error(f"不支持的JSON格式: {args.input}")
            return
    else:
        logger.error(f"不支持的输入文件格式: {args.input}")
        return

    logger.info(f"加载了 {len(input_codes)} 个输入代码")

    # 处理每个输入代码
    all_results = []

    for i, input_item in enumerate(tqdm(input_codes, desc="处理输入")):
        code = input_item["code"]
        file_name = input_item.get("file", f"code_{i + 1}")

        # 构建提示
        prompt = f"请生成一个具有优良PPA指标的Verilog模块:\n\n```verilog\n{code}\n```"

        # 生成代码
        results = generator.generate_and_predict(
            prompt,
            max_length=args.max_length,
            num_return_sequences=args.num_return_sequences,
            temperature=args.temperature,
            top_p=args.top_p
        )

        # 如果有参考PPA，添加比较
        if i < len(reference_ppas):
            for result in results:
                if "ppa_prediction" in result:
                    result["ppa_comparison"] = compare_ppa_metrics(
                        reference_ppas[i],
                        result["ppa_prediction"]
                    )

        # 添加原始代码和文件名
        for result in results:
            result["original_code"] = code
            result["file_name"] = file_name

        all_results.extend(results)

        # 打印第一个结果的摘要
        if results:
            logger.info(f"\n处理 {file_name}:")
            logger.info(f"生成的代码长度: {len(results[0]['code'])}")
            if "ppa_prediction" in results[0]:
                logger.info(f"预测的PPA指标:\n{format_ppa_metrics(results[0]['ppa_prediction'])}")
            if "ppa_comparison" in results[0]:
                logger.info(f"PPA对比:\n{results[0]['ppa_comparison']}")

    # 保存结果
    save_json(all_results, args.output_file)
    logger.info(f"结果已保存到 {args.output_file}")


if __name__ == "__main__":
    main()
