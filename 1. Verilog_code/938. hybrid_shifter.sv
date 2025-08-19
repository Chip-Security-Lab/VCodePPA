module hybrid_shifter #(
    parameter DATA_W = 16,
    parameter SHIFT_W = 4
)(
    input [DATA_W-1:0] din,
    input [SHIFT_W-1:0] shift,
    input dir,  // 0-left, 1-right
    input mode,  // 0-logical, 1-arithmetic
    output [DATA_W-1:0] dout
);
wire [DATA_W-1:0] right_shift = mode ? 
    ({{DATA_W{din[DATA_W-1]}}, din} >> shift) : (din >> shift);
assign dout = dir ? right_shift[DATA_W-1:0] : (din << shift);
endmodule