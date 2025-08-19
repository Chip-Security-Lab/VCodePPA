module GatedDiv(
    input clk, en,
    input [15:0] x, y,
    output reg [15:0] q
);
    always @(posedge clk) 
        if(en) q <= (y != 0) ? x / y : 16'hFFFF;
endmodule