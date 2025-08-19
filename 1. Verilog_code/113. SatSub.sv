module SatSub(input [7:0] a,b, output reg [7:0] res);
    always @(*) res = (a >= b) ? (a - b) : 8'h0;
endmodule