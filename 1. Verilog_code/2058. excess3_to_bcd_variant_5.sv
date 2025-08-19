//SystemVerilog
// Top-level module: Hierarchical Excess-3 to BCD Converter (Optimized)
module excess3_to_bcd (
    input wire [3:0] excess3_in,
    output wire [3:0] bcd_out,
    output wire valid_out
);

    wire [3:0] bcd_converted;
    wire valid_signal;

    // Submodule: Validity Checker for Excess-3 Input (Optimized)
    excess3_input_validator u_validator (
        .excess3_in(excess3_in),
        .valid(valid_signal)
    );

    // Submodule: Excess-3 to BCD Core Converter (Optimized)
    excess3_core_converter u_converter (
        .excess3_in(excess3_in),
        .valid(valid_signal),
        .bcd_out(bcd_converted)
    );

    assign bcd_out = bcd_converted;
    assign valid_out = valid_signal;

endmodule

// -----------------------------------------------------------------------------
// Submodule: Excess-3 Input Validator (Optimized)
// Efficiently checks whether the input is a valid Excess-3 code (range: 3 to 12)
// -----------------------------------------------------------------------------
module excess3_input_validator (
    input wire [3:0] excess3_in,
    output wire valid
);
    // Valid if input is between 4'h3 and 4'hC (inclusive)
    assign valid = ~(excess3_in[3] & ~excess3_in[2]) & (excess3_in != 4'h0) & (excess3_in != 4'h1) & (excess3_in != 4'h2) & (excess3_in <= 4'hC);
endmodule

// -----------------------------------------------------------------------------
// Submodule: Excess-3 Core Converter (Optimized)
// Converts valid Excess-3 code to BCD, outputs 0 if invalid
// -----------------------------------------------------------------------------
module excess3_core_converter (
    input wire [3:0] excess3_in,
    input wire valid,
    output wire [3:0] bcd_out
);
    wire [3:0] bcd_temp;
    assign bcd_temp = excess3_in - 4'h3;
    assign bcd_out = valid ? bcd_temp : 4'h0;
endmodule