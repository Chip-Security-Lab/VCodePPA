//SystemVerilog
//=====================================
// Top Level Module - Binary to Gray Code Converter
//=====================================
module bin2gray_converter #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    // Most significant bit direct connection
    wire msb_bit;
    // Lower bits requiring XOR operation
    wire [WIDTH-2:0] xor_bits;
    
    // MSB handling submodule
    msb_handler #(
        .WIDTH(WIDTH)
    ) msb_handler_inst (
        .bin_msb(bin_in[WIDTH-1]),
        .gray_msb(msb_bit)
    );
    
    // XOR operation submodule for remaining bits
    xor_converter #(
        .WIDTH(WIDTH)
    ) xor_converter_inst (
        .bin_data(bin_in),
        .xor_result(xor_bits)
    );
    
    // Combine results from submodules
    assign gray_out[WIDTH-1] = msb_bit;
    assign gray_out[WIDTH-2:0] = xor_bits;
    
endmodule

//=====================================
// MSB Handler Submodule
//=====================================
module msb_handler #(parameter WIDTH = 8) (
    input  wire bin_msb,
    output wire gray_msb
);
    // For MSB, gray code bit equals binary bit
    assign gray_msb = bin_msb;
endmodule

//=====================================
// XOR Converter Submodule
//=====================================
module xor_converter #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_data,
    output wire [WIDTH-2:0] xor_result
);
    // Perform XOR between adjacent bits
    genvar i;
    generate
        for (i = WIDTH-2; i >= 0; i = i - 1) begin : xor_gen_loop
            assign xor_result[i] = bin_data[i] ^ bin_data[i+1];
        end
    endgenerate
endmodule