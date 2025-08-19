// 使用位异或操作实现逐位比较
module Comparator_BitwiseXOR #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] vec_a,
    input  [WIDTH-1:0] vec_b,
    output             not_equal
);
    wire [WIDTH-1:0] diff_bits;   // 差异位标识
    
    generate
        genvar i;
        for (i=0; i<WIDTH; i=i+1) begin : BIT_CMP
            assign diff_bits[i] = vec_a[i] ^ vec_b[i];
        end
    endgenerate
    
    assign not_equal = |diff_bits; // 或操作检测任意差异
endmodule