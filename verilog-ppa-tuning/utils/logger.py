"""日志工具"""
import os
import sys
import logging
import colorlog
from logging.handlers import RotatingFileHandler
from datetime import datetime


def setup_logger(name="verilog-ppa", level=logging.INFO, log_file=None):
    """
    设置日志记录器

    Args:
        name: 日志名称
        level: 日志级别
        log_file: 日志文件路径

    Returns:
        logging.Logger: 配置好的日志记录器
    """
    # 创建记录器
    logger = logging.getLogger(name)
    logger.setLevel(level)

    # 清除现有的处理器
    if logger.handlers:
        logger.handlers.clear()

    # 控制台处理器
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)

    # 使用彩色日志格式
    colors = {
        'DEBUG': 'cyan',
        'INFO': 'green',
        'WARNING': 'yellow',
        'ERROR': 'red',
        'CRITICAL': 'red,bg_white',
    }

    console_format = colorlog.ColoredFormatter(
        '%(log_color)s[%(asctime)s] [%(levelname)s] [%(name)s] - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        log_colors=colors
    )

    console_handler.setFormatter(console_format)
    logger.addHandler(console_handler)

    # 文件处理器
    if log_file:
        # 确保日志目录存在
        log_dir = os.path.dirname(log_file)
        if log_dir and not os.path.exists(log_dir):
            os.makedirs(log_dir)

        # 添加时间戳到文件名
        log_filename, log_ext = os.path.splitext(log_file)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        log_file = f"{log_filename}_{timestamp}{log_ext}"

        file_handler = RotatingFileHandler(
            log_file, maxBytes=10 * 1024 * 1024, backupCount=5
        )
        file_handler.setLevel(level)

        file_format = logging.Formatter(
            '[%(asctime)s] [%(levelname)s] [%(name)s] - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

        file_handler.setFormatter(file_format)
        logger.addHandler(file_handler)

    return logger


def log_metrics(logger, metrics, prefix=""):
    """
    记录评估指标

    Args:
        logger: 日志记录器
        metrics: 评估指标字典
        prefix: 指标前缀
    """
    for key, value in metrics.items():
        if isinstance(value, dict):
            log_metrics(logger, value, prefix=f"{prefix}{key}/")
        elif isinstance(value, list):
            for i, v in enumerate(value):
                logger.info(f"{prefix}{key}_{i}: {v:.6f}")
        else:
            try:
                logger.info(f"{prefix}{key}: {value:.6f}")
            except:
                logger.info(f"{prefix}{key}: {value}")
