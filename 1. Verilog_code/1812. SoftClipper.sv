module SoftClipper #(parameter W=8, THRESH=8'hF0) (
    input [W-1:0] din,
    output [W-1:0] dout
);
    assign dout = (din > THRESH) ? THRESH + ((din-THRESH)>>1) : 
                 (din < -THRESH) ? -THRESH - ((-THRESH-din)>>1) : din;
endmodule