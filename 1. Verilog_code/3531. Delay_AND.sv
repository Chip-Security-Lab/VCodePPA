`timescale 1ns/1ns
module Delay_AND(
    input a, b,
    output z
);
    assign #3 z = a & b; // 3ns传输延迟
endmodule
