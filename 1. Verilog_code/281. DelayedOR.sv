`timescale 1ns/1ps
module DelayedOR(
    input x, y,
    output z
);
    assign #3 z = x | y;  // 3ns传播延迟
endmodule
