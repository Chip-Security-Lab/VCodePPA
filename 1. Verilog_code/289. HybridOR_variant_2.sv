//SystemVerilog
// Module: Shifter
// Description: Performs a left shift operation based on the shift amount.
module Shifter (
    input [1:0] shift_amount,
    input [7:0] input_data,
    output [7:0] shifted_data
);
    // Calculate the shift amount in bits (shift_amount * 2)
    // Using Karatsuba-like multiplication for 2
    wire [1:0] a = shift_amount;
    wire [1:0] b = 2'd2; // Constant 2

    // Karatsuba-like for 2-bit * 2-bit
    wire [0:0] a0 = a[0];
    wire [0:0] a1 = a[1];
    wire [0:0] b0 = b[0]; // b0 = 0
    wire [0:0] b1 = b[1]; // b1 = 1

    wire [0:0] z0 = a0 & b0; // a[0] & 0 = 0
    wire [0:0] z2 = a1 & b1; // a[1] & 1 = a[1]
    wire [1:0] z1_temp = (a0 | a1) & (b0 | b1); // (a[0]|a[1]) & (0|1) = a[0]|a[1]
    wire [1:0] z1 = z1_temp - z0 - z2; // (a[0]|a[1]) - 0 - a[1] = a[0]

    wire [3:0] actual_shift_bits_karatsuba;
    assign actual_shift_bits_karatsuba = {z2, z1, z0}; // {a[1], a[0], 0}

    assign actual_shift_bits = actual_shift_bits_karatsuba;

    // Perform the left shift
    assign shifted_data = input_data << actual_shift_bits;
endmodule

// Module: MaskGenerator
// Description: Generates a mask based on the shift amount.
module MaskGenerator (
    input [1:0] shift_amount,
    output [7:0] mask_data
);
    // Calculate the shift amount in bits (shift_amount * 2)
    // Using Karatsuba-like multiplication for 2
    wire [1:0] a = shift_amount;
    wire [1:0] b = 2'd2; // Constant 2

    // Karatsuba-like for 2-bit * 2-bit
    wire [0:0] a0 = a[0];
    wire [0:0] a1 = a[1];
    wire [0:0] b0 = b[0]; // b0 = 0
    wire [0:0] b1 = b[1]; // b1 = 1

    wire [0:0] z0 = a0 & b0; // a[0] & 0 = 0
    wire [0:0] z2 = a1 & b1; // a[1] & 1 = a[1]
    wire [1:0] z1_temp = (a0 | a1) & (b0 | b1); // (a[0]|a[1]) & (0|1) = a[0]|a[1]
    wire [1:0] z1 = z1_temp - z0 - z2; // (a[0]|a[1]) - 0 - a[1] = a[0]

    wire [3:0] actual_shift_bits_karatsuba;
    assign actual_shift_bits_karatsuba = {z2, z1, z0}; // {a[1], a[0], 0}

    assign actual_shift_bits = actual_shift_bits_karatsuba;


    // Generate the mask by shifting 8'hFF
    assign mask_data = 8'hFF << actual_shift_bits;
endmodule

// Module: HybridOR
// Description: Top-level module that performs a hybrid OR operation.
// Combines input data with a generated mask based on the selector.
module HybridOR (
    input [1:0] sel,
    input [7:0] data,
    output [7:0] result
);

    // Internal wires to connect sub-modules
    wire [7:0] generated_mask;

    // Instantiate the MaskGenerator sub-module
    MaskGenerator mask_gen_inst (
        .shift_amount (sel),
        .mask_data    (generated_mask)
    );

    // Perform the final OR operation
    assign result = data | generated_mask;

endmodule