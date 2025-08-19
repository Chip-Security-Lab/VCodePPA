module RoundRobinArbiter #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg [WIDTH-1:0] grant
);
reg [WIDTH-1:0] pointer;
always @(posedge clk) begin
    if(rst) {grant, pointer} <= 0;
    else begin
        pointer <= {pointer[WIDTH-2:0], pointer[WIDTH-1]};
        grant <= req & pointer;
    end
end
endmodule
