//SystemVerilog
module WindowMatcher #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input data_valid_in,
    output reg match,
    output reg match_valid
);
    // 定义目标模式常量
    localparam [WIDTH-1:0] TARGET_PATTERN_0 = 8'hA1;
    localparam [WIDTH-1:0] TARGET_PATTERN_1 = 8'hB2;
    localparam [WIDTH-1:0] TARGET_PATTERN_2 = 8'hC3;
    localparam [WIDTH-1:0] TARGET_PATTERN_3 = 8'hD4;
    
    // 流水线数据缓冲区
    reg [WIDTH-1:0] buffer [DEPTH-1:0];
    
    // 流水线各阶段的数据和有效信号
    reg [WIDTH-1:0] data_stage1, data_stage2, data_stage3;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // 流水线各阶段的匹配结果
    reg pattern0_match_stage1, pattern0_match_stage2, pattern0_match_stage3, pattern0_match_stage4;
    reg pattern1_match_stage2, pattern1_match_stage3, pattern1_match_stage4;
    reg pattern2_match_stage3, pattern2_match_stage4;
    reg pattern3_match_stage4;
    
    // 缓冲区数据移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer[0] <= {WIDTH{1'b0}};
            buffer[1] <= {WIDTH{1'b0}};
            buffer[2] <= {WIDTH{1'b0}};
            buffer[3] <= {WIDTH{1'b0}};
        end
        else if (data_valid_in) begin
            buffer[3] <= buffer[2];
            buffer[2] <= buffer[1];
            buffer[1] <= buffer[0];
            buffer[0] <= data_in;
        end
    end
    
    // 流水线阶段1：数据和有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            data_stage1 <= data_in;
            valid_stage1 <= data_valid_in;
        end
    end
    
    // 流水线阶段1：第一个模式检查
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern0_match_stage1 <= 1'b0;
        end
        else begin
            pattern0_match_stage1 <= (data_in == TARGET_PATTERN_0);
        end
    end
    
    // 流水线阶段2：数据和有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段2：第一个模式匹配结果传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern0_match_stage2 <= 1'b0;
        end
        else begin
            pattern0_match_stage2 <= pattern0_match_stage1;
        end
    end
    
    // 流水线阶段2：第二个模式检查
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern1_match_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            pattern1_match_stage2 <= (buffer[0] == TARGET_PATTERN_1);
        end
        else begin
            pattern1_match_stage2 <= 1'b0;
        end
    end
    
    // 流水线阶段3：数据和有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end
        else begin
            data_stage3 <= data_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 流水线阶段3：前两个模式匹配结果传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern0_match_stage3 <= 1'b0;
            pattern1_match_stage3 <= 1'b0;
        end
        else begin
            pattern0_match_stage3 <= pattern0_match_stage2;
            pattern1_match_stage3 <= pattern1_match_stage2;
        end
    end
    
    // 流水线阶段3：第三个模式检查
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern2_match_stage3 <= 1'b0;
        end
        else if (valid_stage2) begin
            pattern2_match_stage3 <= (buffer[1] == TARGET_PATTERN_2);
        end
        else begin
            pattern2_match_stage3 <= 1'b0;
        end
    end
    
    // 流水线阶段4：有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage4 <= 1'b0;
        end
        else begin
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 流水线阶段4：前三个模式匹配结果传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern0_match_stage4 <= 1'b0;
            pattern1_match_stage4 <= 1'b0;
            pattern2_match_stage4 <= 1'b0;
        end
        else begin
            pattern0_match_stage4 <= pattern0_match_stage3;
            pattern1_match_stage4 <= pattern1_match_stage3;
            pattern2_match_stage4 <= pattern2_match_stage3;
        end
    end
    
    // 流水线阶段4：第四个模式检查
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern3_match_stage4 <= 1'b0;
        end
        else if (valid_stage3) begin
            pattern3_match_stage4 <= (buffer[2] == TARGET_PATTERN_3);
        end
        else begin
            pattern3_match_stage4 <= 1'b0;
        end
    end
    
    // 最终匹配计算
    wire final_match;
    assign final_match = pattern0_match_stage4 & pattern1_match_stage4 & 
                        pattern2_match_stage4 & pattern3_match_stage4;
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match <= 1'b0;
            match_valid <= 1'b0;
        end
        else begin
            match_valid <= valid_stage4;
            match <= valid_stage4 ? final_match : 1'b0;
        end
    end
endmodule