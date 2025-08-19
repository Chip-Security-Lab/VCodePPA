module counter_ring #(parameter DEPTH=4) (
    input clk, rst_n,
    output reg [DEPTH-1:0] ring
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) ring <= {1'b1, {DEPTH-1{1'b0}}};
    else ring <= {ring[DEPTH-2:0], ring[DEPTH-1]};
end
endmodule