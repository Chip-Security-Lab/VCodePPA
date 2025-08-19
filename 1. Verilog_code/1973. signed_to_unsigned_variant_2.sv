//SystemVerilog
// Top-level module for signed to unsigned conversion with overflow detection
// Hierarchical decomposition applied

module signed_to_unsigned #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] signed_in,
    output wire [WIDTH-1:0] unsigned_out,
    output wire             overflow
);

    // Internal signal for submodule interface
    wire overflow_flag;
    wire [WIDTH-1:0] unsigned_result;

    // Overflow detection submodule instance
    overflow_detector #(
        .WIDTH(WIDTH)
    ) u_overflow_detector (
        .data_in(signed_in),
        .overflow_flag(overflow_flag)
    );

    // Unsigned conversion submodule instance
    unsigned_converter #(
        .WIDTH(WIDTH)
    ) u_unsigned_converter (
        .data_in(signed_in),
        .unsigned_out(unsigned_result)
    );

    // Output assignments
    assign overflow    = overflow_flag;
    assign unsigned_out = unsigned_result;

endmodule

// -----------------------------------------------------------------------------
// Submodule: overflow_detector
// Purpose: Detects overflow by checking the most significant bit (sign bit)
// -----------------------------------------------------------------------------
module overflow_detector #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] data_in,
    output wire             overflow_flag
);
    assign overflow_flag = data_in[WIDTH-1];
endmodule

// -----------------------------------------------------------------------------
// Submodule: unsigned_converter
// Purpose: Converts signed input to unsigned output; outputs zero if negative
// -----------------------------------------------------------------------------
module unsigned_converter #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] unsigned_out
);
    assign unsigned_out = data_in[WIDTH-1] ? {WIDTH{1'b0}} : data_in;
endmodule