//SystemVerilog
module dual_reset_sync (
    input  wire clock,
    input  wire reset_a_n,
    input  wire reset_b_n,
    output wire synchronized_reset_n
);

    wire combined_reset_n;
    wire meta_stage_next;
    wire meta_stage_d_next;
    reg  meta_stage_reg;
    reg  meta_stage_d_reg;

    // 组合逻辑：异步复位信号合成
    assign combined_reset_n = reset_a_n & reset_b_n;

    // 组合逻辑：下一个状态逻辑
    assign meta_stage_next   = (!combined_reset_n) ? 1'b0 : 1'b1;
    assign meta_stage_d_next = (!combined_reset_n) ? 1'b0 : meta_stage_reg;

    // 时序逻辑：双级同步寄存器
    always @(posedge clock or negedge combined_reset_n) begin
        if (!combined_reset_n) begin
            meta_stage_reg   <= 1'b0;
            meta_stage_d_reg <= 1'b0;
        end else begin
            meta_stage_reg   <= meta_stage_next;
            meta_stage_d_reg <= meta_stage_d_next;
        end
    end

    // 输出同步复位信号
    assign synchronized_reset_n = meta_stage_d_reg;

endmodule