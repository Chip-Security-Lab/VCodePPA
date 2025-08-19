//SystemVerilog
module jk_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire j_in,
    input wire k_in,
    output reg q_out
);
    // 增加流水线级数的中间寄存器
    reg j_stage1, k_stage1;
    reg j_stage2, k_stage2;
    reg q_stage1, q_stage2;
    reg toggling;

    // 第一级流水线：输入寄存
    always @(posedge clock) begin
        if (reset) begin
            j_stage1 <= 1'b0;
            k_stage1 <= 1'b0;
            q_stage1 <= 1'b0;
        end 
        else begin
            j_stage1 <= j_in;
            k_stage1 <= k_in;
            q_stage1 <= q_out;
        end
    end

    // 第二级流水线：计算阶段
    always @(posedge clock) begin
        if (reset) begin
            j_stage2 <= 1'b0;
            k_stage2 <= 1'b0;
            toggling <= 1'b0;
        end 
        else begin
            j_stage2 <= j_stage1;
            k_stage2 <= k_stage1;
            
            // 预计算翻转条件
            toggling <= j_stage1 && k_stage1;
        end
    end

    // 第三级流水线：输出生成
    always @(posedge clock) begin
        if (reset) begin
            q_out <= 1'b0;
        end 
        else begin
            // 使用优化的条件逻辑，基于流水线前级的计算结果
            if (j_stage2 && !k_stage2)
                q_out <= 1'b1;
            else if (!j_stage2 && k_stage2)
                q_out <= 1'b0;
            else if (toggling)
                q_out <= ~q_stage1;
            // 其他情况保持不变
        end
    end
endmodule