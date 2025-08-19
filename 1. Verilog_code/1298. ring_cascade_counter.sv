module ring_cascade_counter (
    input clk, reset,
    output reg [3:0] stages,
    output wire carry_out
);
assign carry_out = (stages == 4'b0001);
always @(posedge clk) begin
    if (reset) stages <= 4'b1000;
    else stages <= {stages[0], stages[3:1]};
end
endmodule
