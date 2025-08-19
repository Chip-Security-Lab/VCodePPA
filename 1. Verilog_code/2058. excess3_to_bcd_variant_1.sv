//SystemVerilog
// Top-level module: Hierarchical Excess-3 to BCD Converter

module excess3_to_bcd (
    input  wire [3:0] excess3_in,
    output wire [3:0] bcd_out,
    output wire       valid_out
);

    // Internal signal for validity
    wire is_valid;

    // Instantiate validity check submodule
    excess3_validity_checker u_validity_checker (
        .excess3_code (excess3_in),
        .is_valid     (is_valid)
    );

    // Instantiate BCD computation submodule
    excess3_bcd_calculator u_bcd_calculator (
        .excess3_code (excess3_in),
        .is_valid     (is_valid),
        .bcd_value    (bcd_out)
    );

    // Instantiate output assignment submodule
    excess3_valid_output u_valid_output (
        .is_valid   (is_valid),
        .valid_flag (valid_out)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: excess3_validity_checker
// Checks if the input Excess-3 code is in valid range (3 to 12)
//------------------------------------------------------------------------------
module excess3_validity_checker (
    input  wire [3:0] excess3_code,
    output reg        is_valid
);
    always @(*) begin
        if (excess3_code >= 4'h3 && excess3_code <= 4'hC)
            is_valid = 1'b1;
        else
            is_valid = 1'b0;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: excess3_bcd_calculator
// Computes BCD output if Excess-3 code is valid, otherwise outputs zero
//------------------------------------------------------------------------------
module excess3_bcd_calculator (
    input  wire [3:0] excess3_code,
    input  wire       is_valid,
    output reg  [3:0] bcd_value
);
    always @(*) begin
        if (is_valid)
            bcd_value = excess3_code - 4'h3;
        else
            bcd_value = 4'h0;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: excess3_valid_output
// Assigns the valid_out signal based on validity flag
//------------------------------------------------------------------------------
module excess3_valid_output (
    input  wire is_valid,
    output reg  valid_flag
);
    always @(*) begin
        valid_flag = is_valid;
    end
endmodule