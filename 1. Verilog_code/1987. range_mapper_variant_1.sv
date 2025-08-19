//SystemVerilog
// Top-level module: Hierarchical Range Mapper with Modular Submodules

module range_mapper #(
    parameter IN_MIN  = 0,
    parameter IN_MAX  = 1023,
    parameter OUT_MIN = 0,
    parameter OUT_MAX = 255
)(
    input  wire [$clog2(IN_MAX-IN_MIN+1)-1:0] in_val,
    output wire [$clog2(OUT_MAX-OUT_MIN+1)-1:0] out_val
);

    // Internal signal declarations
    wire [$clog2(IN_MAX-IN_MIN+1)-1:0] norm_in_val;
    wire [MULT_WIDTH-1:0]               scaled_val;
    wire [MULT_WIDTH-1:0]               div_val;
    wire [$clog2(OUT_MAX-OUT_MIN+1)-1:0] mapped_val;

    // Parameter calculations
    localparam IN_WIDTH   = $clog2(IN_MAX-IN_MIN+1);
    localparam OUT_WIDTH  = $clog2(OUT_MAX-OUT_MIN+1);
    localparam OUT_RANGE  = OUT_MAX - OUT_MIN;
    localparam IN_RANGE   = IN_MAX - IN_MIN;
    localparam MULT_WIDTH = IN_WIDTH + $clog2(OUT_RANGE+1);

    // Normalize input by subtracting IN_MIN
    range_input_normalizer #(
        .IN_MIN   (IN_MIN),
        .IN_WIDTH (IN_WIDTH)
    ) u_range_input_normalizer (
        .in_val   (in_val),
        .out_val  (norm_in_val)
    );

    // Scale normalized input by output range
    range_scaler #(
        .IN_WIDTH   (IN_WIDTH),
        .OUT_RANGE  (OUT_RANGE)
    ) u_range_scaler (
        .in_val     (norm_in_val),
        .scaled_val (scaled_val)
    );

    // Divide scaled value by input range
    range_divider #(
        .IN_WIDTH (MULT_WIDTH),
        .DIVISOR  (IN_RANGE)
    ) u_range_divider (
        .numerator (scaled_val),
        .quotient  (div_val)
    );

    // Truncate to output width
    assign mapped_val = div_val[OUT_WIDTH-1:0];

    // Offset result by OUT_MIN
    range_offset_adder #(
        .OUT_MIN  (OUT_MIN),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_range_offset_adder (
        .in_val   (mapped_val),
        .out_val  (out_val)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: Input Normalizer
// Function: Subtracts IN_MIN from input value to normalize the range
//------------------------------------------------------------------------------
module range_input_normalizer #(
    parameter IN_MIN   = 0,
    parameter IN_WIDTH = 10
)(
    input  wire [IN_WIDTH-1:0] in_val,
    output wire [IN_WIDTH-1:0] out_val
);
    assign out_val = in_val - IN_MIN;
endmodule

//------------------------------------------------------------------------------
// Submodule: Range Scaler
// Function: Multiplies normalized input by the output range
//------------------------------------------------------------------------------
module range_scaler #(
    parameter IN_WIDTH  = 10,
    parameter OUT_RANGE = 255
)(
    input  wire [IN_WIDTH-1:0] in_val,
    output wire [IN_WIDTH+$clog2(OUT_RANGE+1)-1:0] scaled_val
);
    assign scaled_val = in_val * OUT_RANGE;
endmodule

//------------------------------------------------------------------------------
// Submodule: Range Divider
// Function: Divides the scaled value by the input range
//------------------------------------------------------------------------------
module range_divider #(
    parameter IN_WIDTH = 18,
    parameter DIVISOR  = 1023
)(
    input  wire [IN_WIDTH-1:0] numerator,
    output wire [IN_WIDTH-1:0] quotient
);
    assign quotient = numerator / DIVISOR;
endmodule

//------------------------------------------------------------------------------
// Submodule: Range Offset Adder
// Function: Adds OUT_MIN to the mapped value to complete the range mapping
//------------------------------------------------------------------------------
module range_offset_adder #(
    parameter OUT_MIN   = 0,
    parameter OUT_WIDTH = 8
)(
    input  wire [OUT_WIDTH-1:0] in_val,
    output reg  [OUT_WIDTH-1:0] out_val
);
    always @* begin
        out_val = in_val + OUT_MIN;
    end
endmodule