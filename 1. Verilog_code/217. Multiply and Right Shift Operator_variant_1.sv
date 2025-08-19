//SystemVerilog
// 顶层模块
module signed_add_divide (
    input wire clk,
    input wire rst_n,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg signed [7:0] sum,
    output reg signed [7:0] quotient
);

    // 内部信号定义
    wire signed [7:0] add_result;
    wire signed [7:0] div_result;
    reg signed [7:0] a_reg;
    reg signed [7:0] b_reg;
    
    // 输入寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'd0;
            b_reg <= 8'd0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // 实例化加法子模块
    signed_add add_unit (
        .a(a_reg),
        .b(b_reg),
        .sum(add_result)
    );
    
    // 实例化除法子模块
    signed_divide divide_unit (
        .a(a_reg),
        .b(b_reg),
        .quotient(div_result)
    );

    // 输出寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 8'd0;
            quotient <= 8'd0;
        end else begin
            sum <= add_result;
            quotient <= div_result;
        end
    end

endmodule

// 加法子模块
module signed_add (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] sum
);
    // 流水线寄存器
    reg signed [7:0] sum_reg;
    
    // 组合逻辑计算
    always @(*) begin
        sum_reg = a + b;
    end
    
    // 输出赋值
    assign sum = sum_reg;

endmodule

// 除法子模块
module signed_divide (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] quotient
);
    // 流水线寄存器
    reg signed [7:0] quotient_reg;
    
    // 组合逻辑计算
    always @(*) begin
        quotient_reg = a / b;
    end
    
    // 输出赋值
    assign quotient = quotient_reg;

endmodule