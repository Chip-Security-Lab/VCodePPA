//SystemVerilog
// 顶层模块：改造为减法器并使用补码加法实现
module nand2_7 #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] A,
    input  wire [WIDTH-1:0] B,
    output wire [WIDTH-1:0] Y
);
    // 内部连线
    wire [WIDTH-1:0] b_complement;
    wire [WIDTH-1:0] sum_result;
    
    // 计算B的补码 (按位取反后+1)
    assign b_complement = ~B + 1'b1;
    
    // 使用补码加法实现减法: A-B = A+(~B+1)
    assign sum_result = A + b_complement;
    
    // 保留原NAND功能，使用减法结果
    assign Y = ~(sum_result & A);
    
endmodule

// 子模块1：AND操作
module and_module #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] a_in,
    input  wire [WIDTH-1:0] b_in,
    output wire [WIDTH-1:0] y_out
);
    // AND操作实现
    assign y_out = a_in & b_in;
endmodule

// 子模块2：取反操作
module invert_module #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // 取反操作实现
    assign data_out = ~data_in;
endmodule