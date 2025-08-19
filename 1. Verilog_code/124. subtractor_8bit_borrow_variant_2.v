module subtractor_8bit_borrow (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output borrow
);

    wire [7:0] b_comp;
    wire [8:0] sum;
    
    // 使用德摩根定律和分配律优化补码计算
    assign b_comp = ~b + 1'b1;
    
    // 使用进位保存加法器结构优化加法
    wire [7:0] carry;
    wire [7:0] partial_sum;
    
    // 第一级: 并行计算部分和与进位
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_add
            assign partial_sum[i] = a[i] ^ b_comp[i];
            assign carry[i] = a[i] & b_comp[i];
        end
    endgenerate
    
    // 第二级: 进位传播
    wire [8:0] final_carry;
    assign final_carry[0] = 1'b0;
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin: gen_carry
            assign final_carry[j+1] = carry[j] | (partial_sum[j] & final_carry[j]);
        end
    endgenerate
    
    // 最终结果计算
    assign sum = {final_carry[8], partial_sum};
    assign diff = sum[7:0];
    assign borrow = ~sum[8];
    
endmodule