//SystemVerilog
//=============================================================================
// File Name: and_gate_2bit_pipelined.sv
// Description: Optimized 2-bit AND gate with pipelined architecture
//=============================================================================

// 顶层模块 - 优化的2位与门操作
module and_gate_2bit (
    input  wire        clk,      // 时钟信号
    input  wire        rst_n,    // 低电平有效复位信号
    input  wire [1:0]  a,        // 2位输入A
    input  wire [1:0]  b,        // 2位输入B
    output wire [1:0]  y         // 2位输出Y
);
    // 内部信号定义
    logic [1:0] a_reg, b_reg;    // 输入寄存器
    logic [1:0] and_result;      // 与门操作结果
    logic [1:0] y_reg;           // 输出寄存器
    
    // ===== 数据流分段 1: 输入寄存器 =====
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            a_reg <= 2'b00;
            b_reg <= 2'b00;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // ===== 数据流分段 2: 并行化的与门逻辑 =====
    // 位0的与门操作
    bit_and_unit bit0_unit (
        .a_in(a_reg[0]),
        .b_in(b_reg[0]),
        .y_out(and_result[0])
    );
    
    // 位1的与门操作
    bit_and_unit bit1_unit (
        .a_in(a_reg[1]),
        .b_in(b_reg[1]),
        .y_out(and_result[1])
    );
    
    // ===== 数据流分段 3: 输出寄存器 =====
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            y_reg <= 2'b00;
        end else begin
            y_reg <= and_result;
        end
    end
    
    // 将寄存器输出连接到模块输出
    assign y = y_reg;
    
endmodule

// 优化的单比特与门子模块
module bit_and_unit (
    input  wire  a_in,   // 单比特输入A
    input  wire  b_in,   // 单比特输入B
    output wire  y_out   // 单比特输出Y
);
    // 基本与门逻辑实现
    assign y_out = a_in & b_in;
endmodule