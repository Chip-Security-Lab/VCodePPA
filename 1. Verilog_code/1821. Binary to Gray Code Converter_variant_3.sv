//SystemVerilog
module bin2gray_converter #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    // MSB handling
    wire msb_bit;
    msb_handler #(
        .WIDTH(WIDTH)
    ) u_msb_handler (
        .bin_in(bin_in),
        .msb_bit(msb_bit)
    );
    
    // Lower bits conversion
    wire [WIDTH-2:0] lower_bits;
    lower_bits_converter #(
        .WIDTH(WIDTH)
    ) u_lower_bits_converter (
        .bin_in(bin_in),
        .lower_bits(lower_bits)
    );
    
    // Combine results
    assign gray_out = {msb_bit, lower_bits};
    
endmodule

module msb_handler #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire msb_bit
);
    // MSB of Gray code is the same as MSB of binary
    assign msb_bit = bin_in[WIDTH-1];
endmodule

module lower_bits_converter #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-2:0] lower_bits
);
    // Convert lower bits using XOR operation
    genvar i;
    generate
        for (i = WIDTH-2; i >= 0; i = i - 1) begin : gen_gray_bits
            assign lower_bits[i] = bin_in[i] ^ bin_in[i+1];
        end
    endgenerate
endmodule