//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块
module xor2_14 (
    input  wire clk,    // 添加时钟信号用于同步
    input  wire rst_n,  // 添加复位信号用于初始化
    input  wire A, B,
    output wire Y
);
    // 内部连线
    wire registered_a;
    wire registered_b;
    wire xor_result;
    
    // 先对输入信号进行寄存化处理
    xor2_input_registers input_regs (
        .clk(clk),
        .rst_n(rst_n),
        .in_a(A),
        .in_b(B),
        .reg_a(registered_a),
        .reg_b(registered_b)
    );
    
    // 实例化功能子模块 - 现在接收已经寄存的输入
    xor2_logic_core core_inst (
        .in_a(registered_a),
        .in_b(registered_b),
        .xor_out(xor_result)
    );
    
    // 输出缓冲模块直接连接到组合逻辑输出
    xor2_output_buffer output_inst (
        .data_in(xor_result),
        .data_out(Y)
    );
    
endmodule

// 新增：输入寄存器模块
module xor2_input_registers (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  reg_a,
    output reg  reg_b
);
    // 参数化以支持配置
    parameter RESET_VALUE = 1'b0;
    
    // 对输入信号进行寄存处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= RESET_VALUE;
            reg_b <= RESET_VALUE;
        end else begin
            reg_a <= in_a;
            reg_b <= in_b;
        end
    end
    
endmodule

// 核心逻辑运算子模块
module xor2_logic_core (
    input  wire in_a,
    input  wire in_b,
    output wire xor_out
);
    // 参数化实现以支持更多位宽
    parameter WIDTH = 1;
    
    // 优化的异或实现
    assign xor_out = in_a ^ in_b;
    
endmodule

// 输出缓冲子模块
module xor2_output_buffer (
    input  wire data_in,
    output wire data_out
);
    // 输出驱动能力增强
    assign data_out = data_in;
    
    // 参数化设计以支持不同的驱动强度
    parameter DRIVE_STRENGTH = "MEDIUM"; // 可选: "LOW", "MEDIUM", "HIGH"
    
    // 综合指示，指导后端工具优化驱动强度
    // synthesis attribute drive_strength of data_out is DRIVE_STRENGTH
    
endmodule