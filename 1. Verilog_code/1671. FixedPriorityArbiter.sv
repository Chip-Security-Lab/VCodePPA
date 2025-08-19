module FixedPriorityArbiter #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output reg [N-1:0] grant
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) grant <= 0;
    else grant <= req & ~(req-1); // LSB优先
end
endmodule
