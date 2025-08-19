//SystemVerilog
// 顶层模块
module multiply_nand_operator (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product,
    output [7:0] nand_result
);
    // 实例化乘法子模块
    multiplier mult_inst (
        .operand_a(a),
        .operand_b(b),
        .result(product)
    );
    
    // 实例化与非运算子模块
    nand_operator nand_inst (
        .operand_a(a),
        .operand_b(b),
        .result(nand_result)
    );
endmodule

// 乘法运算子模块 - 使用Wallace树实现
module multiplier #(
    parameter WIDTH_A = 8,
    parameter WIDTH_B = 8,
    parameter WIDTH_RESULT = 16
)(
    input [WIDTH_A-1:0] operand_a,
    input [WIDTH_B-1:0] operand_b,
    output [WIDTH_RESULT-1:0] result
);
    // 部分积生成
    wire [WIDTH_RESULT-1:0] partial_products [WIDTH_B-1:0];
    
    genvar i, j;
    generate
        for (i = 0; i < WIDTH_B; i = i + 1) begin : gen_partial_products
            for (j = 0; j < WIDTH_A; j = j + 1) begin : gen_pp_bits
                assign partial_products[i][j] = operand_a[j] & operand_b[i];
            end
            // 高位填充0
            for (j = WIDTH_A; j < WIDTH_RESULT; j = j + 1) begin : gen_pp_padding
                assign partial_products[i][j] = 1'b0;
            end
        end
    endgenerate
    
    // 移位部分积
    wire [WIDTH_RESULT-1:0] shifted_pp [WIDTH_B-1:0];
    generate
        for (i = 0; i < WIDTH_B; i = i + 1) begin : gen_shifted_pp
            assign shifted_pp[i] = partial_products[i] << i;
        end
    endgenerate
    
    // Wallace树压缩
    // 第一级压缩 - 3:2压缩
    wire [WIDTH_RESULT-1:0] level1_sum [2:0];
    wire [WIDTH_RESULT-1:0] level1_carry [2:0];
    
    full_adder_array #(WIDTH_RESULT) fa_level1_0 (
        .a(shifted_pp[0]),
        .b(shifted_pp[1]),
        .c(shifted_pp[2]),
        .sum(level1_sum[0]),
        .carry(level1_carry[0])
    );
    
    full_adder_array #(WIDTH_RESULT) fa_level1_1 (
        .a(shifted_pp[3]),
        .b(shifted_pp[4]),
        .c(shifted_pp[5]),
        .sum(level1_sum[1]),
        .carry(level1_carry[1])
    );
    
    // 处理剩余的部分积
    assign level1_sum[2] = shifted_pp[6];
    assign level1_carry[2] = shifted_pp[7];
    
    // 第二级压缩
    wire [WIDTH_RESULT-1:0] level2_sum [1:0];
    wire [WIDTH_RESULT-1:0] level2_carry [1:0];
    
    full_adder_array #(WIDTH_RESULT) fa_level2_0 (
        .a(level1_sum[0]),
        .b(level1_sum[1]),
        .c(level1_sum[2]),
        .sum(level2_sum[0]),
        .carry(level2_carry[0])
    );
    
    full_adder_array #(WIDTH_RESULT) fa_level2_1 (
        .a(level1_carry[0] << 1),
        .b(level1_carry[1] << 1),
        .c(level1_carry[2] << 1),
        .sum(level2_sum[1]),
        .carry(level2_carry[1])
    );
    
    // 最终加法 - 使用行波进位加法器
    wire [WIDTH_RESULT:0] final_sum;
    wire [WIDTH_RESULT:0] temp_sum;
    wire [WIDTH_RESULT:0] temp_carry;
    
    assign temp_sum[0] = level2_sum[0][0];
    assign temp_carry[0] = 1'b0;
    
    generate
        for (i = 0; i < WIDTH_RESULT; i = i + 1) begin : gen_final_adder
            if (i < WIDTH_RESULT-1) begin
                assign temp_sum[i+1] = level2_sum[0][i+1] ^ level2_sum[1][i] ^ temp_carry[i];
                assign temp_carry[i+1] = (level2_sum[0][i+1] & level2_sum[1][i]) | 
                                        (level2_sum[0][i+1] & temp_carry[i]) | 
                                        (level2_sum[1][i] & temp_carry[i]);
            end else begin
                assign temp_sum[i+1] = level2_sum[1][i] ^ temp_carry[i];
                assign temp_carry[i+1] = level2_sum[1][i] & temp_carry[i];
            end
        end
    endgenerate
    
    // 加上最后的进位
    wire [WIDTH_RESULT:0] final_carry;
    assign final_carry[0] = 1'b0;
    
    generate
        for (i = 0; i < WIDTH_RESULT; i = i + 1) begin : gen_final_carry
            assign final_sum[i] = temp_sum[i] ^ (level2_carry[0][i] << 1) ^ final_carry[i];
            assign final_carry[i+1] = (temp_sum[i] & (level2_carry[0][i] << 1)) | 
                                     (temp_sum[i] & final_carry[i]) | 
                                     ((level2_carry[0][i] << 1) & final_carry[i]);
        end
    endgenerate
    
    assign final_sum[WIDTH_RESULT] = temp_sum[WIDTH_RESULT] ^ final_carry[WIDTH_RESULT];
    
    // 最终结果
    assign result = final_sum[WIDTH_RESULT-1:0];
endmodule

// 全加器阵列模块
module full_adder_array #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [WIDTH-1:0] c,
    output [WIDTH-1:0] sum,
    output [WIDTH-1:0] carry
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_full_adders
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign carry[i] = (a[i] & b[i]) | (a[i] & c[i]) | (b[i] & c[i]);
        end
    endgenerate
endmodule

// 与非运算子模块
module nand_operator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] result
);
    // 对每一位进行与非操作
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : nand_bit
            assign result[i] = ~(operand_a[i] & operand_b[i]);
        end
    endgenerate
endmodule