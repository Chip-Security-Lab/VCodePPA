//SystemVerilog
module freq_divider_en(
    input i_Clock,
    input i_Enable,
    input i_Reset,
    output reg o_Clock
);
    // 将计数器逻辑和时钟切换逻辑分成多个流水线级
    reg [3:0] r_Count_stage1;
    reg count_max_stage1, count_max_stage2;
    reg i_Enable_stage1, i_Enable_stage2;
    reg toggle_pending_stage1, toggle_pending_stage2, toggle_pending_stage3;
    
    // 第一级流水线 - 计数和计数最大值检测
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            r_Count_stage1 <= 4'd0;
            count_max_stage1 <= 1'b0;
            i_Enable_stage1 <= 1'b0;
        end else begin
            i_Enable_stage1 <= i_Enable;
            
            if (i_Enable) begin
                if (r_Count_stage1 == 4'd7) begin
                    r_Count_stage1 <= 4'd0;
                    count_max_stage1 <= 1'b1;
                end else begin
                    r_Count_stage1 <= r_Count_stage1 + 1'b1;
                    count_max_stage1 <= 1'b0;
                end
            end else begin
                count_max_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线 - 处理时钟切换逻辑
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            count_max_stage2 <= 1'b0;
            i_Enable_stage2 <= 1'b0;
            toggle_pending_stage1 <= 1'b0;
        end else begin
            count_max_stage2 <= count_max_stage1;
            i_Enable_stage2 <= i_Enable_stage1;
            
            if (count_max_stage1 && i_Enable_stage1) begin
                toggle_pending_stage1 <= 1'b1;
            end else begin
                toggle_pending_stage1 <= 1'b0;
            end
        end
    end
    
    // 第三级流水线 - 进一步处理时钟切换
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            toggle_pending_stage2 <= 1'b0;
        end else begin
            toggle_pending_stage2 <= toggle_pending_stage1;
        end
    end
    
    // 第四级流水线 - 最终处理时钟切换
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            toggle_pending_stage3 <= 1'b0;
        end else begin
            toggle_pending_stage3 <= toggle_pending_stage2;
        end
    end
    
    // 输出级 - 生成输出时钟
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            o_Clock <= 1'b0;
        end else if (toggle_pending_stage3) begin
            o_Clock <= ~o_Clock;
        end
    end
endmodule