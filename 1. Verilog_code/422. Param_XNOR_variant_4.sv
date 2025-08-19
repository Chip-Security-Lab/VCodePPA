//SystemVerilog
// 顶层模块
module Param_XNOR #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    wire [WIDTH-1:0] xor_result;
    
    // 实例化XOR计算子模块
    XOR_Compute #(
        .WIDTH(WIDTH)
    ) xor_compute_inst (
        .data_a(data_a),
        .data_b(data_b),
        .result(xor_result)
    );
    
    // 实例化结果取反子模块
    Result_Invert #(
        .WIDTH(WIDTH)
    ) result_invert_inst (
        .data_in(xor_result),
        .data_out(result)
    );
    
endmodule

// XOR计算子模块：负责使用条件求和实现XOR功能
module XOR_Compute #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    wire [WIDTH:0] carry;
    assign carry[0] = 1'b0;
    
    // 使用进位链计算XOR
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : conditional_sum
            // 位级XOR计算
            Bit_XOR_Cell bit_xor_inst (
                .a(data_a[i]),
                .b(data_b[i]),
                .c_in(carry[i]),
                .sum(result[i]),
                .c_out(carry[i+1])
            );
        end
    endgenerate
    
endmodule

// 单比特XOR计算单元
module Bit_XOR_Cell (
    input a,
    input b,
    input c_in,
    output sum,
    output c_out
);
    // 计算XOR结果
    assign sum = a ^ b ^ c_in;
    
    // 计算进位
    assign c_out = (a & b) | (a & c_in) | (b & c_in);
    
endmodule

// 结果取反子模块：实现XNOR的最后一步
module Result_Invert #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // XNOR是XOR的取反
    assign data_out = ~data_in;
    
endmodule