module BarrelShifter #(parameter SIZE=16, SHIFT_WIDTH=4) (
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    input en, left,
    output reg [SIZE-1:0] dout
);
always @* if (en) 
    dout = left ? (din << shift) : (din >> shift);
endmodule
