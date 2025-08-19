module yuv_to_rgb_codec #(
    parameter Y_WIDTH = 8,
    parameter UV_WIDTH = 8
) (
    input [Y_WIDTH-1:0] y_in,
    input [UV_WIDTH-1:0] u_in, v_in,
    output [23:0] rgb_out
);
    wire signed [15:0] c = y_in - 16;
    wire signed [15:0] d = u_in - 128;
    wire signed [15:0] e = v_in - 128;
    
    wire [7:0] r = (((298 * c) + (409 * e) + 128) >> 8) > 255 ? 255 : 
                   (((298 * c) + (409 * e) + 128) >> 8) < 0 ? 0 : 
                   ((298 * c) + (409 * e) + 128) >> 8;
    wire [7:0] g = (((298 * c) - (100 * d) - (208 * e) + 128) >> 8) > 255 ? 255 : 
                   (((298 * c) - (100 * d) - (208 * e) + 128) >> 8) < 0 ? 0 : 
                   ((298 * c) - (100 * d) - (208 * e) + 128) >> 8;
    wire [7:0] b = (((298 * c) + (516 * d) + 128) >> 8) > 255 ? 255 : 
                   (((298 * c) + (516 * d) + 128) >> 8) < 0 ? 0 : 
                   ((298 * c) + (516 * d) + 128) >> 8;
    
    assign rgb_out = {r, g, b};
endmodule