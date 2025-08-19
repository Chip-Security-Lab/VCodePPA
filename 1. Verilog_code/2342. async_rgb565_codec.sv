module async_rgb565_codec (
    input [23:0] rgb_in,
    input alpha_en,
    output [15:0] rgb565_out
);
    wire [4:0] red = rgb_in[23:19];
    wire [5:0] green = rgb_in[15:10];
    wire [4:0] blue = rgb_in[7:3];
    
    assign rgb565_out = alpha_en ? {1'b1, red, green, blue} : {red, green, blue};
endmodule