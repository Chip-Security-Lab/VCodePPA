module RomMatcher #(parameter WIDTH=8, ADDR_WIDTH=4) (
    input clk,
    input [WIDTH-1:0] data,
    input [ADDR_WIDTH-1:0] addr,
    output reg match
);
reg [WIDTH-1:0] pattern_rom [2**ADDR_WIDTH-1:0];
always @(posedge clk) match <= (data == pattern_rom[addr]);
endmodule
