//SystemVerilog
// 顶层模块
module priority_token_comparator #(
    parameter TOKEN_WIDTH = 8,
    parameter NUM_TOKENS = 4
)(
    input [TOKEN_WIDTH-1:0] input_token,
    input [TOKEN_WIDTH-1:0] token_array [0:NUM_TOKENS-1],
    input [NUM_TOKENS-1:0] token_valid,
    output match_found,
    output [1:0] match_index,
    output [NUM_TOKENS-1:0] match_bitmap
);
    // 实例化子模块：比较器负责比较输入token与数组中的每个token
    token_comparator #(
        .TOKEN_WIDTH(TOKEN_WIDTH),
        .NUM_TOKENS(NUM_TOKENS)
    ) u_token_comparator (
        .input_token(input_token),
        .token_array(token_array),
        .token_valid(token_valid),
        .match_bitmap(match_bitmap)
    );
    
    // 实例化子模块：优先级编码器确定最高优先级匹配
    priority_encoder #(
        .NUM_TOKENS(NUM_TOKENS)
    ) u_priority_encoder (
        .match_bitmap(match_bitmap),
        .match_found(match_found),
        .match_index(match_index)
    );
endmodule

// 子模块1：token比较器 - 比较输入token与数组中的每个token
module token_comparator #(
    parameter TOKEN_WIDTH = 8,
    parameter NUM_TOKENS = 4
)(
    input [TOKEN_WIDTH-1:0] input_token,
    input [TOKEN_WIDTH-1:0] token_array [0:NUM_TOKENS-1],
    input [NUM_TOKENS-1:0] token_valid,
    output [NUM_TOKENS-1:0] match_bitmap
);
    // 为每个比较操作创建单独的组合逻辑
    wire [NUM_TOKENS-1:0] token_match;
    wire [NUM_TOKENS-1:0] valid_mask;
    
    // 计算每个令牌的匹配信号
    genvar i;
    generate
        for (i = 0; i < NUM_TOKENS; i = i + 1) begin: match_gen
            assign token_match[i] = (input_token == token_array[i]);
            assign valid_mask[i] = token_valid[i];
            // 只有当令牌有效且匹配时才设置匹配位图
            assign match_bitmap[i] = token_match[i] & valid_mask[i];
        end
    endgenerate
endmodule

// 子模块2：优先级编码器 - 确定最高优先级匹配
module priority_encoder #(
    parameter NUM_TOKENS = 4
)(
    input [NUM_TOKENS-1:0] match_bitmap,
    output match_found,
    output reg [1:0] match_index
);
    // 检测是否找到匹配
    assign match_found = |match_bitmap;
    
    // 分解优先级逻辑为多个小规则
    wire has_priority_0 = match_bitmap[0];
    wire has_priority_1 = match_bitmap[1] & ~match_bitmap[0];
    wire has_priority_2 = match_bitmap[2] & ~match_bitmap[1] & ~match_bitmap[0];
    wire has_priority_3 = match_bitmap[3] & ~match_bitmap[2] & ~match_bitmap[1] & ~match_bitmap[0];
    
    // 基于优先级规则设置匹配索引
    always @(*) begin
        case (1'b1) // 优先级case，只有一个条件可以为true
            has_priority_0: match_index = 2'd0;
            has_priority_1: match_index = 2'd1;
            has_priority_2: match_index = 2'd2;
            has_priority_3: match_index = 2'd3;
            default: match_index = 2'd0;
        endcase
    end
endmodule