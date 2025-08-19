module NOR2 #(parameter W=4)(input [W-1:0] a, b, output [W-1:0] y);
    assign y = ~(a | b); // 矢量位运算
endmodule