//SystemVerilog
// 顶层模块 - 实例化并连接子模块
module xor_cond_operator #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] y
);
    // 内部连线
    wire [WIDTH-1:0] sub_result;
    
    // 实例化条件反相减法器子模块
    conditional_subtractor #(
        .BIT_WIDTH(WIDTH)
    ) sub_unit_inst (
        .operand_a(a),
        .operand_b(b),
        .result(sub_result)
    );
    
    // 实例化输出缓冲子模块
    output_buffer #(
        .DATA_WIDTH(WIDTH)
    ) out_buf_inst (
        .data_in(sub_result),
        .data_out(y)
    );
    
endmodule

// 条件反相减法器子模块 - 执行XOR等效操作
module conditional_subtractor #(
    parameter BIT_WIDTH = 8
) (
    input [BIT_WIDTH-1:0] operand_a,
    input [BIT_WIDTH-1:0] operand_b,
    output [BIT_WIDTH-1:0] result
);
    reg [BIT_WIDTH-1:0] sub_result;
    wire [BIT_WIDTH:0] carry;
    wire [BIT_WIDTH-1:0] operand_b_inv;
    
    // 条件反相减法器实现
    assign operand_b_inv = ~operand_b;
    assign carry[0] = 1'b1; // 初始进位为1用于二进制补码
    
    genvar i;
    generate
        for (i = 0; i < BIT_WIDTH; i = i + 1) begin : sub_bit
            assign result[i] = operand_a[i] ^ operand_b_inv[i] ^ carry[i];
            assign carry[i+1] = (operand_a[i] & operand_b_inv[i]) | 
                               (operand_a[i] & carry[i]) | 
                               (operand_b_inv[i] & carry[i]);
        end
    endgenerate
endmodule

// 输出缓冲子模块 - 提供输出隔离
module output_buffer #(
    parameter DATA_WIDTH = 8
) (
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out
);
    // 简单缓冲操作
    assign data_out = data_in;
endmodule