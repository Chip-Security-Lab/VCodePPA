module Shift_AND(
    input [2:0] shift_ctrl,
    input [31:0] vec,
    output [31:0] out
);
    assign out = vec & (32'hFFFFFFFF << shift_ctrl);
endmodule
