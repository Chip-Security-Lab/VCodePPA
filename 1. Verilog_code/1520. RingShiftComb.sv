module RingShiftComb #(parameter RING_SIZE=5) (
    input clk, rotate,
    output wire [RING_SIZE-1:0] ring_out
);
reg [RING_SIZE-1:0] ring_reg = 5'b10000;

always @(posedge clk) begin
    ring_reg <= rotate ? {ring_reg[0], ring_reg[RING_SIZE-1:1]} : ring_reg;
end
assign ring_out = ring_reg;
endmodule
