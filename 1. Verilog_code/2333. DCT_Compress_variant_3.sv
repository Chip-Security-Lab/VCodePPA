//SystemVerilog
module DCT_Compress (
    input clk, en,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    reg signed [15:0] sum = 0;
    wire signed [15:0] product;
    wire signed [15:0] shifted_sum;
    wire [7:0] addition_result;
    
    // 乘法结果 - 使用带符号常量
    assign product = data_in * 16'sd23170;  // cos(π/4) * 32768
    
    // 执行算术右移
    assign shifted_sum = sum >>> 15;
    
    // 使用高效加法器进行加法运算
    EfficientAdder #(8) adder (
        .a(shifted_sum[7:0]),
        .b(8'd128),
        .sum(addition_result)
    );
    
    always @(posedge clk) begin
        if(en) begin
            sum <= product;
            data_out <= addition_result;
        end
    end
endmodule

// 优化的高效加法器模块
module EfficientAdder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    // 直接使用内置的加法操作符
    // 这让综合工具可以更好地优化加法器结构
    assign sum = a + b;
endmodule