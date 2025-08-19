//SystemVerilog
//IEEE 1364-2005 Verilog

module basic_clock_gate #(
    parameter BUFFER_STRENGTH = 1  // 参数化设计，控制缓冲强度
)(
    input  wire clk_in,            // 输入时钟
    input  wire enable,            // 使能信号
    output wire clk_out            // 门控后的输出时钟
);
    // 内部信号定义
    wire gated_clock_internal;
    
    // 实例化层次化子模块
    clock_control_unit clock_ctrl (
        .clk_i(clk_in),
        .enable_i(enable),
        .gated_clk_o(gated_clock_internal)
    );
    
    // 实例化输出缓冲模块
    clock_output_buffer #(
        .STRENGTH(BUFFER_STRENGTH)
    ) output_buffer (
        .clk_i(gated_clock_internal),
        .clk_o(clk_out)
    );
    
endmodule

// 时钟控制单元 - 负责核心门控逻辑
module clock_control_unit (
    input  wire clk_i,        // 输入时钟
    input  wire enable_i,     // 使能信号
    output wire gated_clk_o   // 门控后的时钟
);
    // 使用时钟门控逻辑子模块
    gating_logic gate_logic (
        .clk(clk_i),
        .en(enable_i),
        .gated_clk(gated_clk_o)
    );
endmodule

// 时钟门控核心逻辑
module gating_logic (
    input  wire clk,          // 输入时钟
    input  wire en,           // 使能信号
    output wire gated_clk     // 门控输出
);
    // 核心门控逻辑实现
    // 使用非阻塞赋值以避免潜在的仿真故障
    reg en_latch;
    
    // 当时钟为低电平时锁存使能信号，避免毛刺
    always @(clk or en)
        if (!clk)
            en_latch <= en;
            
    // 生成门控时钟
    assign gated_clk = clk & en_latch;
endmodule

// 时钟输出缓冲模块 - 提供可配置的驱动能力
module clock_output_buffer #(
    parameter STRENGTH = 1    // 缓冲强度参数
)(
    input  wire clk_i,        // 输入时钟
    output wire clk_o         // 缓冲后的时钟输出
);
    // 根据缓冲强度参数实现不同的缓冲策略
    generate
        if (STRENGTH == 1) begin: STANDARD_BUFFER
            // 标准缓冲实现
            assign clk_o = clk_i;
        end
        else if (STRENGTH == 2) begin: MEDIUM_BUFFER
            // 中等强度缓冲实现 - 在实际应用中可替换为特定工艺的缓冲单元
            wire intermediate;
            assign intermediate = clk_i;
            assign clk_o = intermediate;
        end
        else begin: HIGH_BUFFER
            // 高强度缓冲实现 - 在实际应用中可替换为特定工艺的缓冲单元
            wire [1:0] buffer_stages;
            assign buffer_stages[0] = clk_i;
            assign buffer_stages[1] = buffer_stages[0];
            assign clk_o = buffer_stages[1];
        end
    endgenerate
endmodule