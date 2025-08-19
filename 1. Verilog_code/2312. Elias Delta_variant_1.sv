//SystemVerilog
module elias_delta_codec #(
    parameter MAX_WIDTH = 16
)(
    input                      encode_en,
    input  [MAX_WIDTH-1:0]     value_in,
    output [2*MAX_WIDTH-1:0]   code_out,
    output [5:0]               code_len
);
    // Internal signals
    wire [4:0] value_length;    // Length of input value (N)
    wire [4:0] length_of_length;  // Length of N (L)
    wire [2*MAX_WIDTH-1:0] encoded_data;
    wire [5:0] encoded_length;

    // Submodule for finding the bit length of the input value
    bit_length_detector #(
        .INPUT_WIDTH(MAX_WIDTH)
    ) value_length_detector (
        .value_in(value_in),
        .bit_length(value_length)
    );
    
    // Submodule for finding the bit length of N
    bit_length_detector #(
        .INPUT_WIDTH(5)
    ) length_of_length_detector (
        .value_in(value_length),
        .bit_length(length_of_length)
    );
    
    // Submodule for generating the Elias delta code
    elias_delta_encoder #(
        .MAX_WIDTH(MAX_WIDTH)
    ) encoder (
        .encode_en(encode_en),
        .value_in(value_in),
        .value_length(value_length),
        .length_of_length(length_of_length),
        .code_out(encoded_data),
        .code_len(encoded_length)
    );
    
    // Output assignments
    assign code_out = encoded_data;
    assign code_len = encoded_length;
    
endmodule

// Submodule for detecting the bit length of a value
module bit_length_detector #(
    parameter INPUT_WIDTH = 16
)(
    input [INPUT_WIDTH-1:0] value_in,
    output reg [4:0] bit_length
);
    integer i;
    wire [5:0] one_pos;
    
    always @(*) begin
        bit_length = 0;
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
            if (value_in[i])
                bit_length = i + 1;
        end
    end
endmodule

// Submodule for encoding using Elias delta coding
module elias_delta_encoder #(
    parameter MAX_WIDTH = 16
)(
    input                      encode_en,
    input  [MAX_WIDTH-1:0]     value_in,
    input  [4:0]               value_length,     // N
    input  [4:0]               length_of_length, // L
    output [2*MAX_WIDTH-1:0]   code_out,
    output [5:0]               code_len
);
    reg [2*MAX_WIDTH-1:0] temp_code;
    reg [5:0] temp_len;
    
    // Variables for two's complement subtraction
    reg [5:0] unary_prefix_length;
    reg [5:0] binary_N_length;
    reg [5:0] binary_value_length;
    reg [5:0] remaining_bits;
    reg [5:0] total_bits;
    
    integer i;
    
    always @(*) begin
        temp_code = 0;
        temp_len = 0;
        
        if (encode_en) begin
            // Calculate lengths using two's complement subtraction
            unary_prefix_length = length_of_length - 1;
            binary_N_length = length_of_length - 1;
            binary_value_length = value_length - 1;
            
            // Part 1: Add unary prefix (L-1 ones followed by a zero)
            for (i = 0; i < unary_prefix_length; i = i + 1) begin
                temp_code[2*MAX_WIDTH-1-i] = 1;
            end
            temp_code[2*MAX_WIDTH-unary_prefix_length-1] = 0;
            
            // Part 2: Add binary representation of N without MSB
            for (i = 0; i < binary_N_length; i = i + 1) begin
                temp_code[2*MAX_WIDTH-unary_prefix_length-2-i] = value_length[binary_N_length-1-i];
            end
            
            // Part 3: Add binary representation of value without MSB
            remaining_bits = 2*MAX_WIDTH - unary_prefix_length - 1 - binary_N_length;
            for (i = 0; i < binary_value_length; i = i + 1) begin
                temp_code[remaining_bits-1-i] = value_in[binary_value_length-1-i];
            end
                
            // Calculate total code length using two's complement addition
            total_bits = unary_prefix_length + 1 + binary_N_length + binary_value_length;
            temp_len = total_bits;
        end
    end
    
    assign code_out = temp_code;
    assign code_len = temp_len;
endmodule