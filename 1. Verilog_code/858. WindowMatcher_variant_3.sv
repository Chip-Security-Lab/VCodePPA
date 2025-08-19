//SystemVerilog
module WindowMatcher #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg match
);
    // 目标模式常量定义
    localparam [WIDTH-1:0] TARGET_PATTERN_0 = 8'hA1;
    localparam [WIDTH-1:0] TARGET_PATTERN_1 = 8'hB2;
    localparam [WIDTH-1:0] TARGET_PATTERN_2 = 8'hC3;
    localparam [WIDTH-1:0] TARGET_PATTERN_3 = 8'hD4;
    
    // ----- 第一阶段：数据采集和缓冲 -----
    reg [WIDTH-1:0] buffer_stage1 [DEPTH-1:0];
    reg [WIDTH-1:0] buffer_stage2 [DEPTH-1:0];
    integer i;
    
    // ----- 第二阶段：模式比较准备 -----
    reg [WIDTH-1:0] inverted_buf_stage2 [DEPTH-1:0];
    
    // ----- 第三阶段：补码减法计算 -----
    reg [WIDTH:0] diff_stage3 [DEPTH-1:0];
    
    // ----- 第四阶段：匹配检测 -----
    reg [DEPTH-1:0] pattern_match_stage4;
    reg match_found_stage4;
    
    // 数据流水线化实现
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline stages
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer_stage1[i] <= {WIDTH{1'b0}};
                buffer_stage2[i] <= {WIDTH{1'b0}};
                inverted_buf_stage2[i] <= {WIDTH{1'b0}};
                diff_stage3[i] <= {(WIDTH+1){1'b0}};
                pattern_match_stage4[i] <= 1'b0;
            end
            match_found_stage4 <= 1'b0;
            match <= 1'b0;
        end
        else begin
            // Stage 1: 数据采集阶段 - 移位寄存器更新
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                buffer_stage1[i] <= buffer_stage1[i-1];
            end
            buffer_stage1[0] <= data_in;
            
            // Stage 2: 数据准备阶段 - 缓存数据和计算反码
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer_stage2[i] <= buffer_stage1[i];
                inverted_buf_stage2[i] <= ~buffer_stage1[i];
            end
            
            // Stage 3: 补码减法计算阶段
            diff_stage3[0] <= TARGET_PATTERN_0 + inverted_buf_stage2[0] + 1'b1;
            diff_stage3[1] <= TARGET_PATTERN_1 + inverted_buf_stage2[1] + 1'b1;
            diff_stage3[2] <= TARGET_PATTERN_2 + inverted_buf_stage2[2] + 1'b1;
            diff_stage3[3] <= TARGET_PATTERN_3 + inverted_buf_stage2[3] + 1'b1;
            
            // Stage 4: 匹配检测阶段
            for (i = 0; i < DEPTH; i = i + 1) begin
                pattern_match_stage4[i] <= (diff_stage3[i][WIDTH-1:0] == 0);
            end
            
            // 最终匹配结果
            match_found_stage4 <= &pattern_match_stage4;  // 使用按位与运算符简化代码
            match <= match_found_stage4;
        end
    end
endmodule