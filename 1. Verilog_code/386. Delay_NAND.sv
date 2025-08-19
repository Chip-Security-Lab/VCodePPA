`timescale 1ns/1ps
module Delay_NAND(
    input x, y,
    output z
);
    assign #2.5 z = ~(x & y);  // 精确时延
endmodule
