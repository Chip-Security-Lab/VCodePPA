//SystemVerilog
module jk_ff_preset (
    input wire clk,
    input wire preset_n,
    input wire j,
    input wire k,
    input wire valid_in,
    output reg q,
    output reg valid_out
);
    // 流水线寄存器
    reg stage1_j, stage1_k, stage1_q, stage1_valid;
    reg stage2_result, stage2_valid;
    
    // 第一级流水线 - 寄存输入和当前状态
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n) begin
            stage1_j <= 1'b0;
            stage1_k <= 1'b0;
            stage1_q <= 1'b1;  // Preset condition
            stage1_valid <= 1'b0;
        end
        else begin
            stage1_j <= j;
            stage1_k <= k;
            stage1_q <= q;
            stage1_valid <= valid_in;
        end
    end
    
    // 第二级流水线 - 计算JK触发器的下一状态
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n) begin
            stage2_result <= 1'b1;  // Preset condition
            stage2_valid <= 1'b0;
        end
        else begin
            if (stage1_valid) begin
                stage2_result <= (stage1_j & ~stage1_q) | (~stage1_k & stage1_q);
            end
            stage2_valid <= stage1_valid;
        end
    end
    
    // 输出级 - 更新实际输出
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n) begin
            q <= 1'b1;  // Preset condition
            valid_out <= 1'b0;
        end
        else begin
            if (stage2_valid) begin
                q <= stage2_result;
            end
            valid_out <= stage2_valid;
        end
    end
endmodule