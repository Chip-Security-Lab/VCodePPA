module CLA_Sub(input [3:0] A,B, output [3:0] D, Bout);
    wire [4:0] c = {1'b1, ~B};
    assign {Bout, D} = A + c;
endmodule