module delay_ff #(parameter STAGES=2) (
    input clk, d,
    output q
);
reg [STAGES-1:0] shift;
always @(posedge clk) begin
    shift <= {shift[STAGES-2:0], d};
end
assign q = shift[STAGES-1];
endmodule
