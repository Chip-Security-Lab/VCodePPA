//SystemVerilog
module yuv_to_rgb_codec #(
    parameter Y_WIDTH = 8,
    parameter UV_WIDTH = 8
) (
    input [Y_WIDTH-1:0] y_in,
    input [UV_WIDTH-1:0] u_in, v_in,
    output [23:0] rgb_out
);
    // 使用条件反相减法器实现减法运算
    wire [15:0] y_extended = {8'b0, y_in};
    wire [15:0] u_extended = {8'b0, u_in};
    wire [15:0] v_extended = {8'b0, v_in};
    
    // 条件反相减法器实现 c = y_in - 16
    wire [15:0] subtrahend_c = 16'd16;
    wire [15:0] bitwise_xor_c = y_extended ^ subtrahend_c;
    wire [15:0] bitwise_and_c = (~y_extended) & subtrahend_c;
    wire [15:0] temp_c;
    wire borrow_in_c = 1'b1;
    wire [16:0] borrow_chain_c;
    
    assign borrow_chain_c[0] = borrow_in_c;
    
    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin : gen_sub_c
            assign temp_c[i] = bitwise_xor_c[i] ^ borrow_chain_c[i];
            assign borrow_chain_c[i+1] = bitwise_and_c[i] | (bitwise_xor_c[i] & borrow_chain_c[i]);
        end
    endgenerate
    
    wire signed [15:0] c = temp_c;
    
    // 条件反相减法器实现 d = u_in - 128
    wire [15:0] subtrahend_d = 16'd128;
    wire [15:0] bitwise_xor_d = u_extended ^ subtrahend_d;
    wire [15:0] bitwise_and_d = (~u_extended) & subtrahend_d;
    wire [15:0] temp_d;
    wire borrow_in_d = 1'b1;
    wire [16:0] borrow_chain_d;
    
    assign borrow_chain_d[0] = borrow_in_d;
    
    generate
        for(i = 0; i < 16; i = i + 1) begin : gen_sub_d
            assign temp_d[i] = bitwise_xor_d[i] ^ borrow_chain_d[i];
            assign borrow_chain_d[i+1] = bitwise_and_d[i] | (bitwise_xor_d[i] & borrow_chain_d[i]);
        end
    endgenerate
    
    wire signed [15:0] d = temp_d;
    
    // 条件反相减法器实现 e = v_in - 128
    wire [15:0] subtrahend_e = 16'd128;
    wire [15:0] bitwise_xor_e = v_extended ^ subtrahend_e;
    wire [15:0] bitwise_and_e = (~v_extended) & subtrahend_e;
    wire [15:0] temp_e;
    wire borrow_in_e = 1'b1;
    wire [16:0] borrow_chain_e;
    
    assign borrow_chain_e[0] = borrow_in_e;
    
    generate
        for(i = 0; i < 16; i = i + 1) begin : gen_sub_e
            assign temp_e[i] = bitwise_xor_e[i] ^ borrow_chain_e[i];
            assign borrow_chain_e[i+1] = bitwise_and_e[i] | (bitwise_xor_e[i] & borrow_chain_e[i]);
        end
    endgenerate
    
    wire signed [15:0] e = temp_e;
    
    // Pre-compute common term to avoid redundant calculations
    wire signed [23:0] common_term = 298 * c + 128;
    
    // Calculate intermediate results for RGB components
    wire signed [23:0] r_temp = common_term + 409 * e;
    wire signed [23:0] g_temp = common_term - 100 * d - 208 * e;
    wire signed [23:0] b_temp = common_term + 516 * d;
    
    // Shift and clamp in separate steps for clarity
    wire signed [15:0] r_shifted = r_temp >>> 8;
    wire signed [15:0] g_shifted = g_temp >>> 8;
    wire signed [15:0] b_shifted = b_temp >>> 8;
    
    // Use range comparisons for cleaner clamping
    wire [7:0] r = (r_shifted[15]) ? 8'd0 : (|r_shifted[15:8]) ? 8'd255 : r_shifted[7:0];
    wire [7:0] g = (g_shifted[15]) ? 8'd0 : (|g_shifted[15:8]) ? 8'd255 : g_shifted[7:0];
    wire [7:0] b = (b_shifted[15]) ? 8'd0 : (|b_shifted[15:8]) ? 8'd255 : b_shifted[7:0];
    
    assign rgb_out = {r, g, b};

endmodule