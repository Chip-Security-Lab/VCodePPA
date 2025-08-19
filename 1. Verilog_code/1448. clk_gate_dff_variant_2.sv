//SystemVerilog
// Top level module - 重组的时钟门控触发器设计
module clk_gate_dff (
    input  wire clk,     // 系统时钟
    input  wire en,      // 使能信号
    input  wire d,       // 数据输入
    output wire q        // 数据输出
);
    // 定义主数据通路信号
    wire gated_clk;      // 门控时钟信号
    wire valid_data;     // 经过预处理的有效数据
    
    // 阶段1: 时钟门控单元 - 控制时钟通路
    clock_gating_unit u_clock_gate (
        .clk_in     (clk),
        .enable     (en),
        .clk_out    (gated_clk)
    );
    
    // 阶段2: 数据预处理 - 可选的数据处理逻辑
    data_preprocess u_data_prep (
        .data_in    (d),
        .processed  (valid_data)
    );
    
    // 阶段3: 数据寄存单元 - 存储处理后数据
    data_register u_data_reg (
        .clk        (gated_clk),
        .data_in    (valid_data),
        .data_out   (q)
    );
    
endmodule

// 阶段1: 优化的时钟门控单元 - 防止毛刺
module clock_gating_unit (
    input  wire clk_in,   // 输入时钟
    input  wire enable,   // 使能信号
    output wire clk_out   // 门控后时钟
);
    // 使能锁存器和时钟控制
    reg enable_latch;
    
    // 透明锁存器用于防止时钟毛刺
    always @(*)
        if (!clk_in)
            enable_latch <= enable;
    
    // 优化的时钟门控实现
    assign clk_out = clk_in & enable_latch;
    
endmodule

// 阶段2: 数据预处理单元 - 可扩展数据处理
module data_preprocess (
    input  wire data_in,    // 原始输入数据
    output wire processed   // 处理后数据
);
    // 简单直通逻辑，保持与原设计功能一致
    // 此处可扩展为更复杂的数据处理
    assign processed = data_in;
    
endmodule

// 阶段3: 数据寄存单元 - 存储最终结果
module data_register (
    input  wire clk,       // 时钟输入
    input  wire data_in,   // 数据输入
    output reg  data_out   // 寄存后输出
);
    // 寄存器实现
    always @(posedge clk)
        data_out <= data_in;
        
endmodule