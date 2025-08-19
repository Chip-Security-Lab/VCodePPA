//SystemVerilog
module async_pattern_detector #(
    parameter PATTERN_W = 8,
    parameter PATTERN = 8'b10101010
)(
    input [PATTERN_W-1:0] data_in,
    input [PATTERN_W-1:0] mask,
    output pattern_detected
);
    wire [PATTERN_W-1:0] masked_data, masked_pattern;
    wire [PATTERN_W-1:0] pattern_comp;
    wire [PATTERN_W-1:0] sum_result;
    wire carry_out;
    
    assign masked_data = data_in & mask;
    assign masked_pattern = PATTERN & mask;
    
    // 计算补码
    assign pattern_comp = ~masked_pattern + 1'b1;
    
    // 曼彻斯特进位链加法器实现
    wire [PATTERN_W:0] carries;
    wire [PATTERN_W-1:0] gen, prop;
    
    // 生成和传播信号
    assign gen = masked_data & pattern_comp;
    assign prop = masked_data | pattern_comp;
    
    // 初始进位
    assign carries[0] = 1'b0;
    
    // 曼彻斯特进位链
    genvar i;
    generate
        for (i = 0; i < PATTERN_W; i = i + 1) begin : carry_chain
            assign carries[i+1] = gen[i] | (prop[i] & carries[i]);
        end
    endgenerate
    
    // 计算和
    assign sum_result = masked_data ^ pattern_comp ^ carries[PATTERN_W-1:0];
    assign carry_out = carries[PATTERN_W];
    
    // 检测结果是否为零
    assign pattern_detected = (sum_result == 0);
endmodule