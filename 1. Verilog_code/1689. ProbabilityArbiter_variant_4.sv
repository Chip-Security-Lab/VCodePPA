//SystemVerilog
module ProbabilityArbiter #(parameter SEED=8'hA5) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
reg [7:0] lfsr = SEED;
wire [3:0] req_mask = req & {4{|req}};
wire [1:0] lfsr_low = lfsr[1:0];

always @(posedge clk) begin
    lfsr <= rst ? SEED : {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    grant <= rst ? 4'b0 : req_mask & (
        {4{!lfsr_low[1] & !lfsr_low[0]}} & 4'b0001 |
        {4{!lfsr_low[1] &  lfsr_low[0]}} & 4'b0010 |
        {4{ lfsr_low[1] & !lfsr_low[0]}} & 4'b0100 |
        {4{ lfsr_low[1] &  lfsr_low[0]}} & 4'b1000
    );
end
endmodule