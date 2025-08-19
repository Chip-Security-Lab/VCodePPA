import logging
import os
import sys
import colorlog
from logging.handlers import RotatingFileHandler


def setup_logger(name="hvms", level=logging.INFO, log_file=None):
    """
    设置logger配置

    Args:
        name: Logger名称
        level: 日志级别
        log_file: 日志文件路径

    Returns:
        logging.Logger: 配置好的logger
    """
    # 创建logger
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
