module counter_mac #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    output reg [2*WIDTH-1:0] sum
);
always @(posedge clk) begin
    if (rst) sum <= 0;
    else sum <= sum + a * b;
end
endmodule
