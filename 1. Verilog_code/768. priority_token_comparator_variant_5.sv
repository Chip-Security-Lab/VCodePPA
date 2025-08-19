//SystemVerilog
// 顶层模块
module priority_token_comparator #(
    parameter TOKEN_WIDTH = 8,
    parameter NUM_TOKENS = 4
)(
    input [TOKEN_WIDTH-1:0] input_token,
    input [TOKEN_WIDTH-1:0] token_array [0:NUM_TOKENS-1],
    input [NUM_TOKENS-1:0] token_valid,  // Indicates which tokens in the array are valid
    output match_found,
    output [1:0] match_index,        // Index of the highest priority matching token
    output [NUM_TOKENS-1:0] match_bitmap // Bitmap of all tokens that matched
);
    wire [NUM_TOKENS-1:0] match_bits;
    
    // 子模块实例化
    token_matching_unit #(
        .TOKEN_WIDTH(TOKEN_WIDTH),
        .NUM_TOKENS(NUM_TOKENS)
    ) match_unit (
        .input_token(input_token),
        .token_array(token_array),
        .token_valid(token_valid),
        .match_bitmap(match_bits)
    );
    
    priority_encoder #(
        .NUM_TOKENS(NUM_TOKENS)
    ) encoder_unit (
        .match_bitmap(match_bits),
        .match_found(match_found),
        .match_index(match_index)
    );
    
    // 直接将match_bitmap连接到输出
    assign match_bitmap = match_bits;
    
endmodule

// 令牌匹配子模块 - 负责检测输入令牌与令牌数组中的匹配情况
module token_matching_unit #(
    parameter TOKEN_WIDTH = 8,
    parameter NUM_TOKENS = 4
)(
    input [TOKEN_WIDTH-1:0] input_token,
    input [TOKEN_WIDTH-1:0] token_array [0:NUM_TOKENS-1],
    input [NUM_TOKENS-1:0] token_valid,
    output reg [NUM_TOKENS-1:0] match_bitmap
);
    integer i;
    
    always @(*) begin
        match_bitmap = {NUM_TOKENS{1'b0}};
        
        // 并行检查每个令牌是否匹配
        for (i = 0; i < NUM_TOKENS; i = i + 1) begin
            match_bitmap[i] = token_valid[i] && (input_token == token_array[i]);
        end
    end
endmodule

// 优先级编码器子模块 - 确定最高优先级匹配
module priority_encoder #(
    parameter NUM_TOKENS = 4
)(
    input [NUM_TOKENS-1:0] match_bitmap,
    output reg match_found,
    output reg [1:0] match_index
);
    always @(*) begin
        // 检查是否有任何匹配
        match_found = |match_bitmap;
        
        // 使用case语句提高性能
        casez(match_bitmap)
            4'b???1: match_index = 2'd0; // 最高优先级
            4'b??10: match_index = 2'd1;
            4'b?100: match_index = 2'd2;
            4'b1000: match_index = 2'd3;
            default: match_index = 2'd0; // 默认值
        endcase
    end
endmodule