//SystemVerilog
module freq_divider_en(
    input i_Clock,
    input i_Enable,
    input i_Reset,
    output reg o_Clock
);
    // 增加流水线级数，将计数和时钟输出逻辑分开
    reg [3:0] r_Count_stage1;
    reg count_done_stage1;
    reg enable_stage1, enable_stage2;
    reg toggle_clock_stage2;
    
    // 流水线第一级 - 计数和计数完成检测
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            r_Count_stage1 <= 4'd0;
            count_done_stage1 <= 1'b0;
            enable_stage1 <= 1'b0;
        end else begin
            enable_stage1 <= i_Enable;
            
            if (enable_stage1) begin
                if (r_Count_stage1 == 4'd7) begin
                    r_Count_stage1 <= 4'd0;
                    count_done_stage1 <= 1'b1;
                end else begin
                    r_Count_stage1 <= r_Count_stage1 + 1'b1;
                    count_done_stage1 <= 1'b0;
                end
            end else begin
                count_done_stage1 <= 1'b0;
            end
        end
    end
    
    // 流水线第二级 - 时钟翻转控制逻辑
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            enable_stage2 <= 1'b0;
            toggle_clock_stage2 <= 1'b0;
        end else begin
            enable_stage2 <= enable_stage1;
            
            if (enable_stage2 && count_done_stage1) begin
                toggle_clock_stage2 <= 1'b1;
            end else begin
                toggle_clock_stage2 <= 1'b0;
            end
        end
    end
    
    // 流水线第三级 - 时钟输出生成
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            o_Clock <= 1'b0;
        end else if (toggle_clock_stage2) begin
            o_Clock <= ~o_Clock;
        end
    end
endmodule