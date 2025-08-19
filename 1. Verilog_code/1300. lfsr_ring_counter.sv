module lfsr_ring_counter (
    input clk, enable,
    output reg [3:0] lfsr_reg
);
wire feedback = lfsr_reg[0];
always @(posedge clk) begin
    if (enable) lfsr_reg <= {feedback, lfsr_reg[3:1]};
    else lfsr_reg <= 4'b0001;
end
endmodule
