module BusNor(input [3:0] a, b, output [3:0] y);
    assign y = ~(a | b); // 矢量运算
endmodule