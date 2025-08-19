"""Verilog代码生成与PPA预测推理脚本"""
import torch
import json
from transformers import AutoTokenizer
from model.modeling import VerilogPPAModel


class VerilogPPAGenerator:
    """Verilog代码生成器和PPA预测器"""

    def __init__(self, model_path, device=None):
        """
        初始化生成器

        Args:
            model_path: 模型路径
            device: 运行设备
        """
        self.device = device if device else torch.device("cuda" if torch.cuda.is_available() else "cpu")

        # 加载配置
        with open(f"{model_path}/config.json", "r") as f:
            self.config = json.load(f)

        # 加载分词器
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)

        # 加载模型
        self.model = VerilogPPAModel.from_pretrained(model_path)
        self.model.to(self.device)
        self.model.eval()

        # 加载PPA指标统计信息
        try:
            with open(f"{model_path}/ppa_stats.json", "r") as f:
                self.ppa_stats = json.load(f)
        except:
            self.ppa_stats = None

    def generate_code(self, prompt, max_length=2048, num_return_sequences=1, temperature=0.8, top_p=0.9):
        """
        生成优化的Verilog代码

        Args:
            prompt: 输入提示
            max_length: 最大生成长度
            num_return_sequences: 生成序列数量
            temperature: 温度参数
            top_p: 核采样概率

        Returns:
            List[str]: 生成的代码列表
        """
        # 对输入进行编码
        input_ids = self.tokenizer.encode(prompt, return_tensors="pt").to(self.device)

        # 生成代码
        with torch.no_grad():
            outputs = self.model.base_model.generate(
                input_ids,
                max_length=max_length,
                do_sample=True,
                temperature=temperature,
                top_p=top_p,
                num_return_sequences=num_return_sequences,
                pad_token_id=self.tokenizer.pad_token_id,
                eos_token_id=self.tokenizer.eos_token_id,
            )

        # 解码生成的序列
        generated_codes = []
        for output in outputs:
            # 获取生成的代码（从输入部分之后开始）
            generated_text = self.tokenizer.decode(output[input_ids.shape[1]:], skip_special_tokens=True)

            # 提取Verilog代码
            import re
            code_match = re.search(r'```verilog\s+([\s\S]*?)```', generated_text)

            if code_match:
                code = code_match.group(1).strip()
            else:
                # 如果没有找到代码块标记，尝试直接提取模块
                code_match = re.search(r'module\s+[\s\S]+?endmodule', generated_text)
                if code_match:
                    code = code_match.group(0).strip()
                else:
                    # 如果仍然没有找到模块，使用整个生成的文本
                    code = generated_text.strip()

            generated_codes.append(code)

        return generated_codes

    def predict_ppa(self, code):
        """
        预测代码的PPA指标

        Args:
            code: Verilog代码

        Returns:
            dict: 预测的PPA指标
        """
        if not hasattr(self.model, "ppa_head"):
            return None

        # 构建输入提示
        prompt = f"请预测以下Verilog代码的PPA指标:\n\n```verilog\n{code}\n```"

        # 对输入进行编码
        inputs = self.tokenizer(prompt, return_tensors="pt").to(self.device)

        # 预测PPA
        with torch.no_grad():
            outputs = self.model(**inputs, output_hidden_states=True)
            hidden_states = outputs.hidden_states[-1]
            ppa_pred = self.model.ppa_head(hidden_states)

        # 将预测值转换为numpy数组
        ppa_values = ppa_pred.cpu().numpy()[0]

        # 反归一化PPA值
        if self.ppa_stats:
            ppa_metrics = self.config.get("ppa_metrics", [])
            ppa_dict = {}

            for i, metric in enumerate(ppa_metrics):
                if metric in self.ppa_stats:
                    # 使用Z-score反归一化
                    normalized_value = ppa_values[i]
                    mean = self.ppa_stats[metric]["mean"]
                    std = self.ppa_stats[metric]["std"]
                    ppa_dict[metric] = normalized_value * std + mean
                else:
                    ppa_dict[metric] = ppa_values[i]

            return ppa_dict

        # 如果没有统计信息，直接返回归一化的值
        return {metric: value for metric, value in zip(self.config.get("ppa_metrics", []), ppa_values)}

    def generate_and_predict(self, prompt, **kwargs):
        """
        生成代码并预测PPA指标

        Args:
            prompt: 输入提示
            **kwargs: 生成参数

        Returns:
            List[dict]: 生成的代码和对应的PPA预测列表
        """
        # 生成代码
        generated_codes = self.generate_code(prompt, **kwargs)

        # 预测PPA
        results = []
        for code in generated_codes:
            ppa_pred = self.predict_ppa(code)
            results.append({
                "code": code,
                "ppa_prediction": ppa_pred
            })

        return results
