module jk_ff_enable (
    input wire clock_in,
    input wire enable_sig,
    input wire j_input,
    input wire k_input,
    output reg q_output
);
    always @(posedge clock_in) begin
        if (enable_sig) begin
            case ({j_input, k_input})
                2'b00: q_output <= q_output;
                2'b01: q_output <= 1'b0;
                2'b10: q_output <= 1'b1;
                2'b11: q_output <= ~q_output;
            endcase
        end
    end
endmodule
