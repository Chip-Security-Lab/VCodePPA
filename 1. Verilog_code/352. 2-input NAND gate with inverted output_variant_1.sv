//SystemVerilog
//IEEE 1364-2005 Verilog

// 顶层模块 - NAND2 门实现
module nand2_2 (
    input  wire clk,     // 添加时钟输入以支持流水线
    input  wire rst_n,   // 添加复位信号
    input  wire A,
    input  wire B,
    output wire Y
);
    // 内部信号声明 - 流水线级
    wire not_a_stage1, not_b_stage1;  // 第一级流水线输出
    reg  not_a_reg, not_b_reg;        // 寄存器级
    wire Y_comb;                      // 组合逻辑输出
    reg  Y_reg;                       // 输出寄存器
    
    // 第一流水线级 - 输入反相
    inverter_opt inv_a (
        .in(A),
        .out(not_a_stage1)
    );
    
    inverter_opt inv_b (
        .in(B),
        .out(not_b_stage1)
    );
    
    // 寄存器级 - 分割数据路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            not_a_reg <= 1'b0;
            not_b_reg <= 1'b0;
        end else begin
            not_a_reg <= not_a_stage1;
            not_b_reg <= not_b_stage1;
        end
    end
    
    // 第二流水线级 - OR操作
    or_gate_opt or_inst (
        .in1(not_a_reg),
        .in2(not_b_reg),
        .out(Y_comb)
    );
    
    // 输出寄存器 - 最终流水线级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_reg <= 1'b0;
        end else begin
            Y_reg <= Y_comb;
        end
    end
    
    // 输出赋值
    assign Y = Y_reg;
    
endmodule

// 优化的反相器模块
module inverter_opt (
    input  wire in,
    output wire out
);
    // 反相逻辑 - 优化延迟
    assign out = ~in;
endmodule

// 优化的OR门模块
module or_gate_opt (
    input  wire in1,
    input  wire in2,
    output wire out
);
    // OR逻辑 - 优化延迟
    assign out = in1 | in2;
endmodule