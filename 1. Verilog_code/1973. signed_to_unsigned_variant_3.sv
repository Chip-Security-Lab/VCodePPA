//SystemVerilog

// Submodule: sign_detector
// Function: Detects if the input is negative (sign bit is set)
module sign_detector #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] data_in,
    output wire              sign_bit
);
    assign sign_bit = data_in[WIDTH-1];
endmodule

// Submodule: unsigned_selector
// Function: Outputs input value if not negative, else outputs zero
module unsigned_selector #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] data_in,
    input  wire             sign_bit,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = sign_bit ? {WIDTH{1'b0}} : data_in;
endmodule

// Top-level module: signed_to_unsigned
// Function: Converts a signed input to unsigned with overflow detection
module signed_to_unsigned #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] signed_in,
    output wire [WIDTH-1:0] unsigned_out,
    output wire             overflow
);

    wire sign_bit;

    // Instantiate sign detector
    sign_detector #(
        .WIDTH(WIDTH)
    ) u_sign_detector (
        .data_in (signed_in),
        .sign_bit(sign_bit)
    );

    // Instantiate unsigned selector
    unsigned_selector #(
        .WIDTH(WIDTH)
    ) u_unsigned_selector (
        .data_in (signed_in),
        .sign_bit(sign_bit),
        .data_out(unsigned_out)
    );

    // Assign overflow output
    assign overflow = sign_bit;

endmodule