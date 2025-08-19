//SystemVerilog
// Top-level module: fixed_point_truncate
// Function: Truncates a fixed-point input to a smaller width and checks overflow.
// Instantiates two submodules: sign_extend_or_truncate and overflow_detect_lut.

module fixed_point_truncate #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0] in_data,
    output wire [OUT_WIDTH-1:0] out_data,
    output wire                 overflow
);

    wire sign_bit;
    assign sign_bit = in_data[IN_WIDTH-1];

    wire [OUT_WIDTH-1:0] trunc_data;
    wire                 ovf;

    // Submodule: sign_extend_or_truncate
    // Handles sign extension or truncation of input data.
    sign_extend_or_truncate #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_sign_extend_or_truncate (
        .in_data (in_data),
        .sign    (sign_bit),
        .out_data(trunc_data)
    );

    // Submodule: overflow_detect_lut
    // Determines if truncation causes an overflow condition using LUT-based subtraction.
    overflow_detect_lut #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_overflow_detect_lut (
        .in_data (in_data),
        .sign    (sign_bit),
        .overflow(ovf)
    );

    assign out_data = trunc_data;
    assign overflow = ovf;

endmodule

// Submodule: sign_extend_or_truncate
// Performs sign extension if output width is greater than or equal to input width,
// otherwise truncates the input data.
module sign_extend_or_truncate #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0] in_data,
    input  wire                sign,
    output reg  [OUT_WIDTH-1:0] out_data
);
    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            out_data = {{(OUT_WIDTH-IN_WIDTH){sign}}, in_data};
        end else begin
            out_data = in_data[OUT_WIDTH-1:0];
        end
    end
endmodule

// Submodule: lut_subtractor_16bit
// Implements 16-bit subtraction using 8-bit LUT-based subtractions.
module lut_subtractor_16bit (
    input  wire [15:0] minuend,
    input  wire [15:0] subtrahend,
    output wire [15:0] difference,
    output wire        borrow_out
);
    wire [7:0] diff_low;
    wire       borrow_low;
    wire [7:0] diff_high;
    wire       borrow_high;

    // 8-bit LUT-based subtraction, lower byte
    lut_subtractor_8bit u_lut_sub_8b_low (
        .a        (minuend[7:0]),
        .b        (subtrahend[7:0]),
        .diff     (diff_low),
        .borrow_o (borrow_low)
    );

    // 8-bit LUT-based subtraction, higher byte with borrow in
    lut_subtractor_8bit u_lut_sub_8b_high (
        .a        (minuend[15:8]),
        .b        (subtrahend[15:8] + borrow_low),
        .diff     (diff_high),
        .borrow_o (borrow_high)
    );

    assign difference = {diff_high, diff_low};
    assign borrow_out = borrow_high;

endmodule

// Submodule: lut_subtractor_8bit
// 8-bit subtraction using LUT
module lut_subtractor_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] diff,
    output reg        borrow_o
);
    reg [8:0] lut_result;
    always @* begin
        lut_result = {1'b0, a} - {1'b0, b};
        diff = lut_result[7:0];
        borrow_o = lut_result[8];
    end
endmodule

// Submodule: overflow_detect_lut
// Detects overflow when truncating the input data using LUT-based subtraction.
module overflow_detect_lut #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0] in_data,
    input  wire                sign,
    output reg                 overflow
);

    // Local parameters for min/max values
    localparam [IN_WIDTH-1:0] MAX_POS = {1'b0, {(IN_WIDTH-1){1'b1}}};
    localparam [IN_WIDTH-1:0] MIN_NEG = {1'b1, {(IN_WIDTH-1){1'b0}}};

    // Truncated data
    wire [OUT_WIDTH-1:0] trunc_data;
    assign trunc_data = in_data[OUT_WIDTH-1:0];

    // Sign-extended trunc data to IN_WIDTH bits
    wire [IN_WIDTH-1:0] trunc_ext;
    assign trunc_ext = {{(IN_WIDTH-OUT_WIDTH){trunc_data[OUT_WIDTH-1]}}, trunc_data};

    // LUT-based difference
    wire [IN_WIDTH-1:0] diff;
    wire                borrow;
    // Overflow if in_data < min or in_data > max after truncation

    // Check positive overflow: in_data > max
    wire [IN_WIDTH-1:0] max_val;
    assign max_val = {trunc_data[OUT_WIDTH-1], {(IN_WIDTH-OUT_WIDTH){trunc_data[OUT_WIDTH-1]}}, trunc_data};

    wire [IN_WIDTH-1:0] diff_pos;
    wire                borrow_pos;
    lut_subtractor_16bit u_lut_sub_pos (
        .minuend   (in_data),
        .subtrahend(max_val),
        .difference(diff_pos),
        .borrow_out(borrow_pos)
    );

    // Check negative overflow: in_data < min
    wire [IN_WIDTH-1:0] min_val;
    assign min_val = {trunc_data[OUT_WIDTH-1], {(IN_WIDTH-OUT_WIDTH){trunc_data[OUT_WIDTH-1]}}, trunc_data};

    wire [IN_WIDTH-1:0] diff_neg;
    wire                borrow_neg;
    lut_subtractor_16bit u_lut_sub_neg (
        .minuend   (min_val),
        .subtrahend(in_data),
        .difference(diff_neg),
        .borrow_out(borrow_neg)
    );

    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            overflow = 1'b0;
        end else begin
            // If in_data > max_val or in_data < min_val -> overflow
            overflow = borrow_pos | borrow_neg;
        end
    end

endmodule