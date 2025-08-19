`timescale 1ns/1ps
module DelayedNOT(
    input a,
    output y
);
    assign #2 y = ~a;  // 显式传播延迟
endmodule
