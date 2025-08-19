//SystemVerilog
module async_pattern_detector #(
    parameter PATTERN_W = 8,
    parameter PATTERN = 8'b10101010
)(
    input [PATTERN_W-1:0] data_in,
    input [PATTERN_W-1:0] mask,
    output pattern_detected
);
    // 使用条件反相减法器算法进行模式匹配
    wire [PATTERN_W-1:0] masked_data, masked_pattern;
    wire [PATTERN_W:0] borrow;
    wire [PATTERN_W-1:0] diff;
    
    // 应用掩码
    assign masked_data = data_in & mask;
    assign masked_pattern = PATTERN & mask;
    
    // 条件反相减法器实现
    // borrow[0]初始为0
    assign borrow[0] = 1'b0;
    
    // 生成每位的借位和差值
    genvar i;
    generate
        for (i = 0; i < PATTERN_W; i = i + 1) begin: sub_loop
            assign diff[i] = masked_data[i] ^ masked_pattern[i] ^ borrow[i];
            assign borrow[i+1] = (~masked_data[i] & masked_pattern[i]) | 
                                 (~masked_data[i] & borrow[i]) | 
                                 (borrow[i] & masked_pattern[i]);
        end
    endgenerate
    
    // 如果差值为0，则模式匹配
    assign pattern_detected = (diff == 0);
endmodule