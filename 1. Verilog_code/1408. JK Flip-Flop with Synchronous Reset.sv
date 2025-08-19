module jk_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire j_in,
    input wire k_in,
    output reg q_out
);
    always @(posedge clock) begin
        if (reset)
            q_out <= 1'b0;
        else begin
            case ({j_in, k_in})
                2'b00: q_out <= q_out;
                2'b01: q_out <= 1'b0;
                2'b10: q_out <= 1'b1;
                2'b11: q_out <= ~q_out;
            endcase
        end
    end
endmodule