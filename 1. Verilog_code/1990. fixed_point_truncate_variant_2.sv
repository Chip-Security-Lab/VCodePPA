//SystemVerilog
// Top-level module: fixed_point_truncate
module fixed_point_truncate #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0] in_data,
    output wire [OUT_WIDTH-1:0] out_data,
    output wire                 overflow
);

    // Internal signals for submodule interconnection
    wire sign_bit;
    wire [IN_WIDTH-1:0] trunc_in_data;
    wire [OUT_WIDTH-1:0] trunc_out_data;
    wire trunc_overflow;

    // Extract sign bit
    assign sign_bit = in_data[IN_WIDTH-1];

    // Data truncation and sign-extension submodule
    fixed_point_truncate_data #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_truncate_data (
        .in_data      (in_data),
        .sign_bit     (sign_bit),
        .out_data     (trunc_out_data)
    );

    // Overflow detection submodule
    fixed_point_truncate_overflow #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_truncate_overflow (
        .in_data   (in_data),
        .sign_bit  (sign_bit),
        .overflow  (trunc_overflow)
    );

    assign out_data = trunc_out_data;
    assign overflow = trunc_overflow;

endmodule

// ---------------------------------------------------------------------------
// Submodule: fixed_point_truncate_data
// Function: Handles fixed point truncation and sign-extension as needed
// ---------------------------------------------------------------------------
module fixed_point_truncate_data #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0] in_data,
    input  wire                sign_bit,
    output reg  [OUT_WIDTH-1:0] out_data
);
    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            // Sign-extend if output is wider
            out_data = {{(OUT_WIDTH-IN_WIDTH){sign_bit}}, in_data};
        end else begin
            // Truncate to lower OUT_WIDTH bits
            out_data = in_data[OUT_WIDTH-1:0];
        end
    end
endmodule

// ---------------------------------------------------------------------------
// Submodule: fixed_point_truncate_overflow
// Function: Detects overflow during truncation
// ---------------------------------------------------------------------------
module fixed_point_truncate_overflow #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0] in_data,
    input  wire                sign_bit,
    output reg                 overflow
);
    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            overflow = 1'b0;
        end else begin
            if (sign_bit) begin
                // Negative: overflow if any upper bit (excluding sign) is not set
                overflow = |(~in_data[IN_WIDTH-2:OUT_WIDTH-1]);
            end else begin
                // Positive: overflow if any upper bit is set
                overflow = |in_data[IN_WIDTH-1:OUT_WIDTH];
            end
        end
    end
endmodule