//SystemVerilog
module jk_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire j_in,
    input wire k_in,
    output reg q_out
);
    // 使用多级条件判断替代复杂表达式
    always @(posedge clock) begin
        if (reset) begin
            q_out <= 1'b0;
        end else begin
            case ({j_in, k_in})
                2'b00: q_out <= q_out;     // 保持当前状态
                2'b01: q_out <= 1'b0;      // 置零
                2'b10: q_out <= 1'b1;      // 置一
                2'b11: q_out <= ~q_out;    // 翻转
            endcase
        end
    end
endmodule