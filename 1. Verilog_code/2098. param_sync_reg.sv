module param_sync_reg #(parameter WIDTH=4) (
    input clk1, clk2, rst,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] sync_reg;
    always @(posedge clk1) sync_reg <= din;
    always @(posedge clk2) dout <= sync_reg;
endmodule