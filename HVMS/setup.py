from setuptools import setup, find_packages

setup(
    name="hvms",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "numpy",
        "pyyaml",
        "tqdm",
        "pandas",
        "pyverilog",
        # 添加其他依赖
    ],
    entry_points={
        'console_scripts': [
            'hvms=main:main',
        ],
    },
    author="Your Name",
    author_email="your.email@example.com",
    description="Homologous Heterogeneous Verilog Mutation Search Framework",
)