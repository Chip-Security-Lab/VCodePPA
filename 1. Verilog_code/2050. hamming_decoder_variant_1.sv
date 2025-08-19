//SystemVerilog

//-----------------------------
// Top-level Hamming Decoder
//-----------------------------
module hamming_decoder (
    input wire [6:0] hamming_in,
    output wire [3:0] data_out,
    output wire error_detected
);
    wire [2:0] syndrome;
    wire [2:0] error_position;
    wire [6:0] corrected_codeword;
    wire error_flag;

    // Syndrome computation submodule
    hamming_syndrome_calc u_syndrome_calc (
        .codeword_in(hamming_in),
        .syndrome_out(syndrome)
    );

    // Error position and flag decoding
    hamming_error_locator u_error_locator (
        .syndrome_in(syndrome),
        .error_position(error_position),
        .error_flag(error_flag)
    );

    // Error correction submodule
    hamming_error_corrector u_error_corrector (
        .codeword_in(hamming_in),
        .error_flag(error_flag),
        .error_position(error_position),
        .corrected_codeword(corrected_codeword)
    );

    // Data extraction submodule
    hamming_data_extractor u_data_extractor (
        .codeword_in(corrected_codeword),
        .data_out(data_out)
    );

    assign error_detected = error_flag;

endmodule

//-----------------------------
// Syndrome Calculation Module
//-----------------------------
// Computes the (3-bit) syndrome from the received Hamming code.
module hamming_syndrome_calc (
    input wire [6:0] codeword_in,
    output wire [2:0] syndrome_out
);
    assign syndrome_out[0] = codeword_in[0] ^ codeword_in[2] ^ codeword_in[4] ^ codeword_in[6];
    assign syndrome_out[1] = codeword_in[1] ^ codeword_in[2] ^ codeword_in[5] ^ codeword_in[6];
    assign syndrome_out[2] = codeword_in[3] ^ codeword_in[4] ^ codeword_in[5] ^ codeword_in[6];
endmodule

//-----------------------------
// Error Locator Module
//-----------------------------
// Converts syndrome to error position and error flag.
module hamming_error_locator (
    input wire [2:0] syndrome_in,
    output wire [2:0] error_position,
    output wire error_flag
);
    assign error_position = syndrome_in;
    assign error_flag = |syndrome_in;
endmodule

//-----------------------------
// Error Corrector Module
//-----------------------------
// Corrects single-bit error if detected.
module hamming_error_corrector (
    input wire [6:0] codeword_in,
    input wire error_flag,
    input wire [2:0] error_position,
    output wire [6:0] corrected_codeword
);
    wire [6:0] error_mask;
    assign error_mask = (error_flag && (error_position != 3'b000)) ? (7'b1 << (error_position - 1)) : 7'b0;
    assign corrected_codeword = codeword_in ^ error_mask;
endmodule

//-----------------------------
// Data Extractor Module
//-----------------------------
// Extracts decoded data bits from corrected codeword.
module hamming_data_extractor (
    input wire [6:0] codeword_in,
    output wire [3:0] data_out
);
    assign data_out = {codeword_in[6], codeword_in[5], codeword_in[4], codeword_in[2]};
endmodule

//-----------------------------
// Top-level 7-bit Karatsuba Multiplier
//-----------------------------
module karatsuba_mult_7bit (
    input  wire [6:0] operand_a,
    input  wire [6:0] operand_b,
    output wire [13:0] product
);
    wire [3:0] a_high, a_low;
    wire [3:0] b_high, b_low;
    wire [6:0] z2, z0, z1;
    wire [3:0] sum_a, sum_b;
    wire [7:0] z1_temp;

    assign a_high = operand_a[6:3];
    assign a_low  = {1'b0, operand_a[2:0]};
    assign b_high = operand_b[6:3];
    assign b_low  = {1'b0, operand_b[2:0]};

    // z2 = a_high * b_high
    karatsuba_mult_4bit u_z2 (
        .operand_a(a_high),
        .operand_b(b_high),
        .product(z2)
    );

    // z0 = a_low * b_low
    karatsuba_mult_3bit u_z0 (
        .operand_a(a_low[2:0]),
        .operand_b(b_low[2:0]),
        .product(z0)
    );

    // z1 = (a_high + a_low) * (b_high + b_low) - z2 - z0
    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;

    karatsuba_mult_4bit u_z1 (
        .operand_a(sum_a),
        .operand_b(sum_b),
        .product(z1_temp)
    );

    assign z1 = z1_temp[6:0] - z2 - z0;

    assign product = ({z2,6'b0}) + ({z1,3'b0}) + z0;
endmodule

//-----------------------------
// 4-bit Karatsuba Multiplier
//-----------------------------
module karatsuba_mult_4bit (
    input  wire [3:0] operand_a,
    input  wire [3:0] operand_b,
    output wire [6:0] product
);
    wire [1:0] a_high, a_low;
    wire [1:0] b_high, b_low;
    wire [3:0] z2, z0, z1;
    wire [2:0] sum_a, sum_b;
    wire [4:0] z1_temp;

    assign a_high = operand_a[3:2];
    assign a_low  = operand_a[1:0];
    assign b_high = operand_b[3:2];
    assign b_low  = operand_b[1:0];

    // z2 = a_high * b_high
    karatsuba_mult_2bit u_z2 (
        .operand_a(a_high),
        .operand_b(b_high),
        .product(z2)
    );

    // z0 = a_low * b_low
    karatsuba_mult_2bit u_z0 (
        .operand_a(a_low),
        .operand_b(b_low),
        .product(z0)
    );

    // z1 = (a_high + a_low) * (b_high + b_low) - z2 - z0
    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;

    karatsuba_mult_3bit u_z1 (
        .operand_a(sum_a),
        .operand_b(sum_b),
        .product(z1_temp)
    );

    assign z1 = z1_temp[3:0] - z2 - z0;

    assign product = ({z2,4'b0}) + ({z1,2'b0}) + z0;
endmodule

//-----------------------------
// 3-bit Karatsuba Multiplier
//-----------------------------
module karatsuba_mult_3bit (
    input  wire [2:0] operand_a,
    input  wire [2:0] operand_b,
    output wire [4:0] product
);
    wire [1:0] a_high, a_low;
    wire [1:0] b_high, b_low;
    wire [1:0] a_sum, b_sum;
    wire [3:0] z2, z0, z1, z1_temp;

    assign a_high = operand_a[2:1];
    assign a_low  = {1'b0, operand_a[0]};
    assign b_high = operand_b[2:1];
    assign b_low  = {1'b0, operand_b[0]};

    // z2 = a_high * b_high
    karatsuba_mult_2bit u_z2 (
        .operand_a(a_high),
        .operand_b(b_high),
        .product(z2)
    );

    // z0 = a_low * b_low
    karatsuba_mult_2bit u_z0 (
        .operand_a(a_low),
        .operand_b(b_low),
        .product(z0)
    );

    // z1 = (a_high + a_low) * (b_high + b_low) - z2 - z0
    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    karatsuba_mult_2bit u_z1 (
        .operand_a(a_sum),
        .operand_b(b_sum),
        .product(z1_temp)
    );

    assign z1 = z1_temp - z2 - z0;

    assign product = ({z2,2'b0}) + ({z1,1'b0}) + z0;
endmodule

//-----------------------------
// 2-bit Karatsuba Multiplier
//-----------------------------
// Final base case, uses simple multiplication
module karatsuba_mult_2bit (
    input  wire [1:0] operand_a,
    input  wire [1:0] operand_b,
    output wire [3:0] product
);
    wire [1:0] a_high, a_low;
    wire [1:0] b_high, b_low;
    wire [1:0] z2, z0, z1, z1_temp;

    assign a_high = {1'b0, operand_a[1]};
    assign a_low  = {1'b0, operand_a[0]};
    assign b_high = {1'b0, operand_b[1]};
    assign b_low  = {1'b0, operand_b[0]};

    assign z2 = a_high * b_high;
    assign z0 = a_low  * b_low;
    assign z1_temp = (a_high + a_low) * (b_high + b_low);
    assign z1 = z1_temp - z2 - z0;

    assign product = {z2,2'b0} + {z1,1'b0} + z0;
endmodule