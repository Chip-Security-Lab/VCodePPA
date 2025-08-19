//SystemVerilog
// Top-level module for BCD to Binary conversion with hierarchical structure
module bcd2bin (
    input  wire [11:0] bcd_in,   // 3 BCD digits: {hundreds[11:8], tens[7:4], ones[3:0]}
    output wire [9:0]  bin_out   // Binary output (0~999)
);

    wire [7:0] hundreds_val;
    wire [7:0] tens_val;
    wire [3:0] ones_val;
    wire [9:0] hundreds_scaled;
    wire [7:0] tens_scaled;
    wire [9:0] bin_sum;

    // Extract BCD digits
    bcd_extract u_bcd_extract (
        .bcd_in      (bcd_in),
        .hundreds    (hundreds_val),
        .tens        (tens_val),
        .ones        (ones_val)
    );

    // Multiply hundreds digit by 100 (signed multiplication optimized)
    bcd_scale_hundred u_bcd_scale_hundred (
        .hundreds_in (hundreds_val),
        .hundreds_scaled (hundreds_scaled)
    );

    // Multiply tens digit by 10 (signed multiplication optimized)
    bcd_scale_ten u_bcd_scale_ten (
        .tens_in     (tens_val),
        .tens_scaled (tens_scaled)
    );

    // Sum all parts
    bcd_bin_sum u_bcd_bin_sum (
        .hundreds_scaled (hundreds_scaled),
        .tens_scaled     (tens_scaled),
        .ones            (ones_val),
        .bin_out         (bin_sum)
    );

    assign bin_out = bin_sum;

endmodule

// ----------------------------------------------------------------------
// Submodule: BCD Digit Extractor
// Extracts hundreds, tens, and ones BCD digits from input
// ----------------------------------------------------------------------
module bcd_extract (
    input  wire [11:0] bcd_in,
    output wire [7:0]  hundreds, // 8 bits to match scaling unit
    output wire [7:0]  tens,     // 8 bits to match scaling unit
    output wire [3:0]  ones
);
    assign hundreds = {4'b0, bcd_in[11:8]};
    assign tens     = {4'b0, bcd_in[7:4]};
    assign ones     = bcd_in[3:0];
endmodule

// ----------------------------------------------------------------------
// Submodule: BCD Hundreds Scaler (Signed Optimized Multiplier)
// Multiplies hundreds BCD digit by 100 using signed multiplication algorithm
// ----------------------------------------------------------------------
module bcd_scale_hundred (
    input  wire [7:0] hundreds_in,
    output wire [9:0] hundreds_scaled
);
    wire signed [11:0] signed_hundreds;
    wire signed [11:0] signed_hundred_const;
    wire signed [23:0] signed_mult_result;

    assign signed_hundreds      = $signed({4'b0000, hundreds_in[7:0]}); // sign-extend to 12 bits
    assign signed_hundred_const = 12'sd100; // 12-bit signed constant 100

    assign signed_mult_result   = signed_hundreds * signed_hundred_const;

    assign hundreds_scaled      = signed_mult_result[9:0];
endmodule

// ----------------------------------------------------------------------
// Submodule: BCD Tens Scaler (Signed Optimized Multiplier)
// Multiplies tens BCD digit by 10 using signed multiplication algorithm
// ----------------------------------------------------------------------
module bcd_scale_ten (
    input  wire [7:0] tens_in,
    output wire [7:0] tens_scaled
);
    wire signed [11:0] signed_tens;
    wire signed [11:0] signed_ten_const;
    wire signed [23:0] signed_tens_mult;

    assign signed_tens      = $signed({4'b0000, tens_in[7:0]}); // sign-extend to 12 bits
    assign signed_ten_const = 12'sd10; // 12-bit signed constant 10

    assign signed_tens_mult = signed_tens * signed_ten_const;

    assign tens_scaled      = signed_tens_mult[7:0];
endmodule

// ----------------------------------------------------------------------
// Submodule: BCD to Binary Summer
// Sums scaled hundreds, tens, and ones values to produce the binary output
// ----------------------------------------------------------------------
module bcd_bin_sum (
    input  wire [9:0] hundreds_scaled,
    input  wire [7:0] tens_scaled,
    input  wire [3:0] ones,
    output wire [9:0] bin_out
);
    assign bin_out = hundreds_scaled + {2'b00, tens_scaled} + {6'b000000, ones};
endmodule