//SystemVerilog
module Comparator_GrayCode #(
    parameter WIDTH = 4,
    parameter THRESHOLD = 1
)(
    input  [WIDTH-1:0] gray_code_a,
    input  [WIDTH-1:0] gray_code_b,
    output             is_adjacent  
);

    // 格雷码差异检测
    wire [WIDTH-1:0] xor_result = gray_code_a ^ gray_code_b;
    
    // 曼彻斯特进位链加法器实现
    wire [WIDTH:0] carry;
    wire [WIDTH:0] sum;
    
    // 初始化
    assign carry[0] = 1'b0;
    
    // 曼彻斯特进位链
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : gen_manchester
            // 生成进位
            wire g = xor_result[i];
            wire p = xor_result[i];
            
            // 曼彻斯特进位计算
            assign carry[i+1] = g | (p & carry[i]);
            
            // 和计算
            assign sum[i] = xor_result[i] ^ carry[i];
        end
    endgenerate
    
    // 最终进位
    assign sum[WIDTH] = carry[WIDTH];
    
    // 比较结果
    assign is_adjacent = (sum <= THRESHOLD);

endmodule