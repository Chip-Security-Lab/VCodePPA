module parallel_load_ring (
    input clk, load,
    input [3:0] parallel_in,
    output reg [3:0] ring
);
always @(posedge clk) begin
    ring <= load ? parallel_in : {ring[0], ring[3:1]};
end
endmodule
