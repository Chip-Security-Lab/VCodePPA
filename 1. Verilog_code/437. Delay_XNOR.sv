`timescale 1ns/1ps
module Delay_XNOR(
    input a, b,
    output z
);
    assign #1.8 z = ~(a ^ b); // 1.8ns传输延迟
endmodule
