//SystemVerilog
// 顶层模块
module PriorityMatcher #(parameter WIDTH=8, DEPTH=4) (
    input [WIDTH-1:0] data,
    input [DEPTH*WIDTH-1:0] patterns,
    output [$clog2(DEPTH)-1:0] match_index,
    output valid
);
    // 内部信号定义
    wire [DEPTH-1:0] match_signals;
    
    // 实例化模式匹配器子模块
    PatternMatcher #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) pattern_matcher_inst (
        .data(data),
        .patterns(patterns),
        .match_signals(match_signals)
    );
    
    // 实例化优先编码器子模块
    PriorityEncoder #(
        .DEPTH(DEPTH)
    ) priority_encoder_inst (
        .match_signals(match_signals),
        .match_index(match_index),
        .valid(valid)
    );
endmodule

// 模式匹配器子模块 - 负责并行检测所有模式
module PatternMatcher #(parameter WIDTH=8, DEPTH=4) (
    input [WIDTH-1:0] data,
    input [DEPTH*WIDTH-1:0] patterns,
    output [DEPTH-1:0] match_signals
);
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : match_gen
            assign match_signals[i] = (data == patterns[i*WIDTH +: WIDTH]);
        end
    endgenerate
endmodule

// 优先编码器子模块 - 负责确定优先级最高的匹配
module PriorityEncoder #(parameter DEPTH=4) (
    input [DEPTH-1:0] match_signals,
    output reg [$clog2(DEPTH)-1:0] match_index,
    output reg valid
);
    integer i;
    
    always @* begin
        valid = 0;
        match_index = 0;
        
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (match_signals[i] && !valid) begin
                valid = 1;
                match_index = i[$clog2(DEPTH)-1:0];
            end
        end
    end
endmodule