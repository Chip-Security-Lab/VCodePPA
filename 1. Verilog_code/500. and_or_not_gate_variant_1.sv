//SystemVerilog
// 顶层模块，集成各个子模块
module and_or_not_gate (
    input  wire clk,      // 时钟输入
    input  wire rst_n,    // 异步复位（低有效）
    input  wire A, B, C,  // 输入信号
    output wire Y         // 输出信号
);
    // 内部连线
    wire A_r, B_r, C_r;        // 第一级流水线输出
    
    // 实例化输入寄存器子模块
    input_register input_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(A),
        .B_in(B),
        .C_in(C),
        .A_out(A_r),
        .B_out(B_r),
        .C_out(C_r)
    );
    
    // 实例化布尔逻辑计算子模块
    boolean_logic logic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .A(A_r),
        .B(B_r),
        .C(C_r),
        .Y(Y)
    );
    
endmodule

// 第一级流水线：输入信号寄存器模块
module input_register (
    input  wire clk,           // 时钟输入
    input  wire rst_n,         // 异步复位（低有效）
    input  wire A_in, B_in, C_in,  // 输入信号
    output reg  A_out, B_out, C_out  // 寄存后的输出信号
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_out <= 1'b0;
            B_out <= 1'b0;
            C_out <= 1'b0;
        end else begin
            A_out <= A_in;
            B_out <= B_in;
            C_out <= C_in;
        end
    end
    
endmodule

// 第二级流水线：布尔逻辑计算模块
module boolean_logic (
    input  wire clk,       // 时钟输入
    input  wire rst_n,     // 异步复位（低有效）
    input  wire A, B, C,   // 来自第一级流水线的输入
    output reg  Y          // 最终输出
);
    
    // 使用德摩根定律: A&B | ~C = ~(~(A&B) & C) = ~((~A | ~B) & C)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= ~((~A | ~B) & C);
        end
    end
    
endmodule