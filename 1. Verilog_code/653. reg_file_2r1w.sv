module reg_file_2r1w #(
    parameter WIDTH = 32,
    parameter DEPTH = 32
)(
    input clk,
    input [4:0]  ra1,
    output [WIDTH-1:0] rd1,
    input [4:0]  ra2,
    output [WIDTH-1:0] rd2,
    input [4:0]  wa,
    input we,
    input [WIDTH-1:0] wd
);
reg [WIDTH-1:0] rf [0:DEPTH-1];
assign rd1 = rf[ra1];
assign rd2 = rf[ra2];
always @(posedge clk) begin
    if (we) rf[wa] <= wd;
end
endmodule
