module Sub5(input [3:0] A,B, output [3:0] D, output Bout);
    wire [4:0] c = {1'b1, ~B + 1'b1};
    assign {Bout, D} = A + c;
endmodule