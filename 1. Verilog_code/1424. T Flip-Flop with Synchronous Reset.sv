module t_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire toggle,
    output reg q_out
);
    always @(posedge clock) begin
        if (reset)
            q_out <= 1'b0;
        else
            q_out <= toggle ? ~q_out : q_out;
    end
endmodule