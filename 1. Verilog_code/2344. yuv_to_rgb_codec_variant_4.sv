//SystemVerilog
//IEEE 1364-2005 Verilog
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
    
    reg [7:0] r, g, b;
    
    // Calculate intermediate results with optimized multiplications
    wire signed [31:0] r_temp = (298 * c) + (409 * e) + 128;
    wire signed [31:0] g_temp = (298 * c) - (100 * d) - (208 * e) + 128;
    wire signed [31:0] b_temp = (298 * c) + (516 * d) + 128;
    
    // Extract the relevant 8 bits for comparison
    wire signed [9:0] r_shifted = r_temp[17:8]; // 1 sign bit + 9 data bits
    wire signed [9:0] g_shifted = g_temp[17:8];
    wire signed [9:0] b_shifted = b_temp[17:8];
    
    // Optimized clipping logic using range checks
    always @(*) begin
        // Use range checks to simplify comparison logic
        r = (r_shifted[9] || r_shifted > 255) ? 8'd255 :
            (r_shifted < 0) ? 8'd0 : r_shifted[7:0];
            
        g = (g_shifted[9] || g_shifted > 255) ? 8'd255 :
            (g_shifted < 0) ? 8'd0 : g_shifted[7:0];
            
        b = (b_shifted[9] || b_shifted > 255) ? 8'd255 :
            (b_shifted < 0) ? 8'd0 : b_shifted[7:0];
    end
    
    // Pack RGB components
    assign rgb_out = {r, g, b};
endmodule