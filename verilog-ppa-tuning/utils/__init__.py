"""工具函数包"""
import os
import sys

# 添加项目根目录到Python路径
root_dir = "/public/home/u43077/JYX/Fine-tuning/verilog-ppa-tuning"
if root_dir not in sys.path:
    sys.path.append(root_dir)