//SystemVerilog
module char_gen (
    input wire clk,
    input wire rst_n,
    input wire [9:0] h_cnt, v_cnt,
    input wire valid_in,
    output reg valid_out,
    output reg pixel,
    output reg blank
);
    parameter CHAR_WIDTH = 8;
    
    // 预计算组合逻辑结果
    wire blank_comb;
    reg pixel_comb;
    
    // 计算blank_comb
    assign blank_comb = (h_cnt > 640) || (v_cnt > 480);
    
    // 将条件运算符转换为always块中的if-else结构
    always @(*) begin
        if (h_cnt[2:0] < CHAR_WIDTH) begin
            pixel_comb = 1'b1;
        end else begin
            pixel_comb = 1'b0;
        end
    end
    
    // 第一级流水线：直接捕获组合逻辑的结果
    reg blank_stage1, pixel_stage1, valid_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blank_stage1 <= 1'b1;
            pixel_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            blank_stage1 <= blank_comb;
            pixel_stage1 <= pixel_comb;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：进一步处理数据
    reg blank_stage2, pixel_stage2, valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blank_stage2 <= 1'b1;
            pixel_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            blank_stage2 <= blank_stage1;
            pixel_stage2 <= pixel_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blank <= 1'b1;
            pixel <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            blank <= blank_stage2;
            pixel <= pixel_stage2;
            valid_out <= valid_stage2;
        end
    end
    
endmodule