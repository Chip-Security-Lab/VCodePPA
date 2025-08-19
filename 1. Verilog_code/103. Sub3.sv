module Sub3 #(parameter W=4)(input [W-1:0] a,b, output [W-1:0] res);
    assign res = a - b;
endmodule