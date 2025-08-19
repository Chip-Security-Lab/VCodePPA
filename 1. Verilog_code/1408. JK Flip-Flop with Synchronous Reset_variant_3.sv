//SystemVerilog
module jk_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire j_in,
    input wire k_in,
    output reg q_out
);
    // 流水线寄存器
    reg j_stage1, k_stage1, q_stage1;
    reg valid_stage1;
    reg q_next;
    
    // 第一级流水线：寄存输入信号
    always @(posedge clock) begin
        if (reset) begin
            j_stage1 <= 1'b0;
            k_stage1 <= 1'b0;
            q_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            j_stage1 <= j_in;
            k_stage1 <= k_in;
            q_stage1 <= q_out;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线：计算并更新输出
    always @(posedge clock) begin
        if (reset) begin
            q_out <= 1'b0;
        end else if (valid_stage1) begin
            q_out <= j_stage1 ^ (j_stage1 & q_stage1) | (q_stage1 & ~k_stage1);
        end
    end
endmodule