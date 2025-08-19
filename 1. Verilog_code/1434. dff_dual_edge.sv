module dff_dual_edge (
    input clk, rstn,
    input d,
    output q
);
reg q_pos, q_neg;

// Positive edge FF
always @(posedge clk or negedge rstn) begin
    if (!rstn) q_pos <= 0;
    else       q_pos <= d;
end

// Negative edge FF
always @(negedge clk or negedge rstn) begin
    if (!rstn) q_neg <= 0;
    else       q_neg <= d;
end

// Output one of the flip-flops depending on the clock
assign q = clk ? q_pos : q_neg;
endmodule