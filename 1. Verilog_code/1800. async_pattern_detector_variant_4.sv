//SystemVerilog
module async_pattern_detector #(
    parameter PATTERN_W = 8,
    parameter PATTERN = 8'b10101010
)(
    input [PATTERN_W-1:0] data_in,
    input [PATTERN_W-1:0] mask,
    output pattern_detected
);
    // 直接比较masked_data与masked_pattern
    // 通过使用XNOR操作取代XOR+比较零的组合
    wire [PATTERN_W-1:0] match_bits;
    
    // 生成每位匹配结果(1表示匹配，0表示不匹配)
    assign match_bits = ~((data_in & mask) ^ (PATTERN & mask));
    
    // 只有当所有关心位匹配时才激活检测信号
    assign pattern_detected = &(match_bits | ~mask);
endmodule