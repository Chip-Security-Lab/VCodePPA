//SystemVerilog
module bitwise_mix (
    input [7:0] data_a,
    input [7:0] data_b,
    output [7:0] xor_out,
    output [7:0] nand_out
);
    // 实例化异或操作子模块
    xor_operation xor_inst (
        .a(data_a),
        .b(data_b),
        .result(xor_out)
    );
    
    // 实例化与非操作子模块
    nand_operation nand_inst (
        .a(data_a),
        .b(data_b),
        .result(nand_out)
    );
endmodule

// 异或操作子模块
module xor_operation #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    // 使用生成块实现可参数化的按位异或
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : xor_gen
            assign result[i] = a[i] ^ b[i];
        end
    endgenerate
endmodule

// 与非操作子模块
module nand_operation #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    // 使用生成块实现可参数化的按位与非
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : nand_gen
            assign result[i] = ~(a[i] & b[i]);
        end
    endgenerate
endmodule