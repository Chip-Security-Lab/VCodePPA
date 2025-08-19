module rgb_to_gray_codec (
    input [23:0] rgb_pixel,
    output [7:0] gray_out
);
    // Standard luminance calculation: Y = 0.299R + 0.587G + 0.114B
    wire [15:0] r_contrib = 77 * rgb_pixel[23:16];  // 0.299 * 256 ~= 77
    wire [15:0] g_contrib = 150 * rgb_pixel[15:8];  // 0.587 * 256 ~= 150
    wire [15:0] b_contrib = 29 * rgb_pixel[7:0];    // 0.114 * 256 ~= 29
    
    assign gray_out = (r_contrib + g_contrib + b_contrib) >> 8;
endmodule