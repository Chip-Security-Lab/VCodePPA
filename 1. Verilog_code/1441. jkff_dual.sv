module jkff_dual (
    input clk, rstn,
    input j, k,
    output q
);
reg q_pos, q_neg;

// Positive edge FF
always @(posedge clk or negedge rstn) begin
    if (!rstn) q_pos <= 0;
    else case ({j,k})
        2'b00: q_pos <= q_pos;  // No change
        2'b10: q_pos <= 1;      // Set
        2'b01: q_pos <= 0;      // Reset
        2'b11: q_pos <= ~q_pos; // Toggle
        default: q_pos <= q_pos;
    endcase
end

// Negative edge FF
always @(negedge clk or negedge rstn) begin
    if (!rstn) q_neg <= 0;
    else case ({j,k})
        2'b00: q_neg <= q_neg;  // No change
        2'b10: q_neg <= 1;      // Set
        2'b01: q_neg <= 0;      // Reset
        2'b11: q_neg <= ~q_neg; // Toggle
        default: q_neg <= q_neg;
    endcase
end

// Output one of the flip-flops depending on the clock
assign q = clk ? q_pos : q_neg;
endmodule