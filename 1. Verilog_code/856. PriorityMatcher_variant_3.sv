//SystemVerilog
module PriorityMatcher #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
) (
    input [WIDTH-1:0] data,
    input [DEPTH*WIDTH-1:0] patterns,
    output [$clog2(DEPTH)-1:0] match_index,
    output valid
);
    wire [DEPTH-1:0] match_signals;
    
    PatternComparator #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) pattern_comp_inst (
        .data(data),
        .patterns(patterns),
        .match_signals(match_signals)
    );
    
    PriorityEncoder #(
        .DEPTH(DEPTH)
    ) priority_enc_inst (
        .match_signals(match_signals),
        .match_index(match_index),
        .valid(valid)
    );
endmodule

module PatternComparator #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
) (
    input [WIDTH-1:0] data,
    input [DEPTH*WIDTH-1:0] patterns,
    output [DEPTH-1:0] match_signals
);
    wire [DEPTH-1:0] [WIDTH-1:0] pattern_array;
    assign pattern_array = patterns;
    
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : pattern_match
            assign match_signals[i] = (data == pattern_array[i]);
        end
    endgenerate
endmodule

module PriorityEncoder #(
    parameter DEPTH = 4
) (
    input [DEPTH-1:0] match_signals,
    output [$clog2(DEPTH)-1:0] match_index,
    output valid
);
    wire [DEPTH-1:0] masked_signals;
    wire [DEPTH-1:0] priority_mask;
    
    // 生成优先级掩码
    assign priority_mask[0] = 1'b1;
    genvar i;
    generate
        for (i = 1; i < DEPTH; i = i + 1) begin : mask_gen
            assign priority_mask[i] = ~(|match_signals[i-1:0]);
        end
    endgenerate
    
    // 应用优先级掩码
    assign masked_signals = match_signals & priority_mask;
    
    // 使用查找表实现编码
    assign valid = |match_signals;
    assign match_index = masked_signals[0] ? 0 :
                        masked_signals[1] ? 1 :
                        masked_signals[2] ? 2 :
                        masked_signals[3] ? 3 : 0;
endmodule