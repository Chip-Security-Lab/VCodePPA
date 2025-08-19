//SystemVerilog
// Top-level Module: Hierarchical Range Mapper (Re-architected with Functional Submodules)
module range_mapper #(
    parameter IN_MIN  = 0,
    parameter IN_MAX  = 1023,
    parameter OUT_MIN = 0,
    parameter OUT_MAX = 255
)(
    input  wire [IN_WIDTH-1:0] in_val,
    output wire [OUT_WIDTH-1:0] out_val
);
    // Parameterized width definitions
    localparam IN_WIDTH   = $clog2(IN_MAX - IN_MIN + 1);
    localparam OUT_WIDTH  = $clog2(OUT_MAX - OUT_MIN + 1);

    // Internal signals for submodule interconnection
    wire [IN_WIDTH-1:0] offset_in;
    wire [MULT_WIDTH-1:0] scaled_val;
    wire [OUT_WIDTH-1:0] mapped_val;

    localparam MULT_WIDTH = IN_WIDTH + OUT_WIDTH;

    // Input Offset Submodule: Aligns input to start from zero
    range_mapper_input_offset #(
        .IN_MIN(IN_MIN),
        .IN_WIDTH(IN_WIDTH)
    ) u_input_offset (
        .in_val(in_val),
        .offset_in(offset_in)
    );

    // Range Scaling Submodule: Performs scaling from input range to output range
    range_mapper_scaler #(
        .IN_RANGE(IN_MAX - IN_MIN),
        .OUT_RANGE(OUT_MAX - OUT_MIN),
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .MULT_WIDTH(MULT_WIDTH)
    ) u_scaler (
        .offset_in(offset_in),
        .scaled_val(scaled_val)
    );

    // Output Offset Submodule: Adds output minimum to scaled value
    range_mapper_output_offset #(
        .OUT_MIN(OUT_MIN),
        .OUT_WIDTH(OUT_WIDTH),
        .MULT_WIDTH(MULT_WIDTH)
    ) u_output_offset (
        .scaled_val(scaled_val),
        .out_val(mapped_val)
    );

    // Top-level output assignment
    assign out_val = mapped_val;

endmodule

// -----------------------------------------------------------------------------
// Submodule: range_mapper_input_offset
// Function: Subtracts IN_MIN from input value to align input range to zero
module range_mapper_input_offset #(
    parameter IN_MIN   = 0,
    parameter IN_WIDTH = 10
)(
    input  wire [IN_WIDTH-1:0] in_val,
    output wire [IN_WIDTH-1:0] offset_in
);
    assign offset_in = in_val - IN_MIN;
endmodule

// -----------------------------------------------------------------------------
// Submodule: range_mapper_scaler
// Function: Multiplies offset input by OUT_RANGE, divides by IN_RANGE
module range_mapper_scaler #(
    parameter IN_RANGE  = 1023,
    parameter OUT_RANGE = 255,
    parameter IN_WIDTH  = 10,
    parameter OUT_WIDTH = 8,
    parameter MULT_WIDTH = 18
)(
    input  wire [IN_WIDTH-1:0] offset_in,
    output wire [MULT_WIDTH-1:0] scaled_val
);
    wire [MULT_WIDTH-1:0] mult_result;
    assign mult_result = offset_in * OUT_RANGE;
    assign scaled_val  = mult_result / IN_RANGE;
endmodule

// -----------------------------------------------------------------------------
// Submodule: range_mapper_output_offset
// Function: Adds OUT_MIN to the scaled value to map to output range
module range_mapper_output_offset #(
    parameter OUT_MIN   = 0,
    parameter OUT_WIDTH = 8,
    parameter MULT_WIDTH = 18
)(
    input  wire [MULT_WIDTH-1:0] scaled_val,
    output wire [OUT_WIDTH-1:0] out_val
);
    assign out_val = scaled_val[OUT_WIDTH-1:0] + OUT_MIN;
endmodule