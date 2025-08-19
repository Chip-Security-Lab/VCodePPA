module Sub6(input [7:0] a,b, input en, output reg [7:0] res);
    always @(*) res = en ? a - b : 0;
endmodule