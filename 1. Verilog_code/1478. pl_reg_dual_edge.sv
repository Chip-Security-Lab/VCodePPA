module pl_reg_dual_edge #(parameter W=8) (
    input clk, load, rstn,
    input [W-1:0] d,
    output [W-1:0] q
);
reg [W-1:0] q_pos, q_neg;

// Positive edge FF
always @(posedge clk or negedge rstn) begin
    if (!rstn) q_pos <= 0;
    else if (load) q_pos <= d;
end

// Negative edge FF
always @(negedge clk or negedge rstn) begin
    if (!rstn) q_neg <= 0;
    else if (load) q_neg <= d;
end

// Output mux based on clock value
assign q = clk ? q_pos : q_neg;
endmodule