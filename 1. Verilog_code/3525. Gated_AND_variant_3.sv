//SystemVerilog
module Gated_AND(
    input enable,
    input [3:0] vec_a, vec_b,
    output reg [7:0] res
);
    // 中间信号声明
    wire [15:0] partial_products;
    wire [7:0] result;
    
    // Baugh-Wooley乘法器实现
    // 生成部分积
    assign partial_products[0] = vec_a[0] & vec_b[0];
    assign partial_products[1] = vec_a[0] & vec_b[1];
    assign partial_products[2] = vec_a[0] & vec_b[2];
    assign partial_products[3] = ~(vec_a[0] & vec_b[3]);  // 符号位取反
    
    assign partial_products[4] = vec_a[1] & vec_b[0];
    assign partial_products[5] = vec_a[1] & vec_b[1];
    assign partial_products[6] = vec_a[1] & vec_b[2];
    assign partial_products[7] = ~(vec_a[1] & vec_b[3]);  // 符号位取反
    
    assign partial_products[8] = vec_a[2] & vec_b[0];
    assign partial_products[9] = vec_a[2] & vec_b[1];
    assign partial_products[10] = vec_a[2] & vec_b[2];
    assign partial_products[11] = ~(vec_a[2] & vec_b[3]); // 符号位取反
    
    assign partial_products[12] = ~(vec_a[3] & vec_b[0]); // 符号位取反
    assign partial_products[13] = ~(vec_a[3] & vec_b[1]); // 符号位取反
    assign partial_products[14] = ~(vec_a[3] & vec_b[2]); // 符号位取反
    assign partial_products[15] = vec_a[3] & vec_b[3];    // 符号位位置为正
    
    // 累加部分积形成最终结果
    assign result[0] = partial_products[0];
    assign result[1] = partial_products[1] ^ partial_products[4];
    assign result[2] = partial_products[2] ^ partial_products[5] ^ partial_products[8];
    assign result[3] = partial_products[3] ^ partial_products[6] ^ partial_products[9] ^ partial_products[12];
    assign result[4] = partial_products[7] ^ partial_products[10] ^ partial_products[13];
    assign result[5] = partial_products[11] ^ partial_products[14];
    assign result[6] = partial_products[15];
    assign result[7] = 1'b1; // Baugh-Wooley补偿位
    
    // 控制逻辑
    always @(*) begin
        if (enable) begin
            res = result;
        end else begin
            res = 8'b00000000;
        end
    end
endmodule