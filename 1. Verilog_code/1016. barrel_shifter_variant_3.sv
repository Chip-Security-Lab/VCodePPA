//SystemVerilog
// Top-level Barrel Shifter Module (Hierarchical Structure)
module barrel_shifter #(parameter N = 8) (
    input  wire [N-1:0]                in,
    input  wire [$clog2(N)-1:0]        shift,
    output wire [N-1:0]                out
);

    // Internal signals for shifted values
    wire [N-1:0] left_shifted;
    wire [N-1:0] right_shifted;
    wire [N-1:0] left_shifted_rot;

    // Left Shift Module instance
    left_shifter #(.N(N)) u_left_shifter (
        .data_in (in),
        .shift   (shift),
        .data_out(left_shifted)
    );

    // Right Shift Module instance
    right_shifter #(.N(N)) u_right_shifter (
        .data_in (in),
        .shift   (shift),
        .data_out(right_shifted)
    );

    // Left Rotator Module instance
    left_rotator #(.N(N)) u_left_rotator (
        .data_in (left_shifted),
        .shift   (shift),
        .data_out(left_shifted_rot)
    );

    // Combiner Module instance (bitwise OR)
    shifter_combiner #(.N(N)) u_shifter_combiner (
        .left_rotated (left_shifted_rot),
        .right_shifted(right_shifted),
        .out          (out)
    );

endmodule

// -----------------------------------------------------------------------------
// Left Shifter Module
// Performs logical left shift on input data
// -----------------------------------------------------------------------------
module left_shifter #(parameter N = 8) (
    input  wire [N-1:0]         data_in,
    input  wire [$clog2(N)-1:0] shift,
    output wire [N-1:0]         data_out
);
    assign data_out = data_in << shift;
endmodule

// -----------------------------------------------------------------------------
// Right Shifter Module
// Performs logical right shift on input data
// -----------------------------------------------------------------------------
module right_shifter #(parameter N = 8) (
    input  wire [N-1:0]         data_in,
    input  wire [$clog2(N)-1:0] shift,
    output wire [N-1:0]         data_out
);
    assign data_out = data_in >> shift;
endmodule

// -----------------------------------------------------------------------------
// Left Rotator Module
// Rotates left-shifted data by (N-shift) bits using conditional sum subtraction
// -----------------------------------------------------------------------------
module left_rotator #(parameter N = 8) (
    input  wire [N-1:0]         data_in,
    input  wire [$clog2(N)-1:0] shift,
    output wire [N-1:0]         data_out
);
    wire [$clog2(N)-1:0] rot_shift;

    // Conditional Sum Subtraction for rot_shift = N - shift
    wire [$clog2(N)-1:0] sum_stage0;
    wire [$clog2(N)-1:0] carry_stage0;
    wire [$clog2(N)-1:0] sum_stage1;
    wire [$clog2(N)-1:0] carry_stage1;
    wire [$clog2(N)-1:0] sum_stage2;
    wire [$clog2(N)-1:0] carry_stage2;
    wire [$clog2(N)-1:0] sum_final;
    wire                 carry_out;

    // Prepare N as a constant vector
    wire [$clog2(N)-1:0] n_const;
    assign n_const = N[$clog2(N)-1:0];

    // Stage 0: bitwise add with inverted shift and initial carry-in
    genvar i;
    generate
        for (i = 0; i < $clog2(N); i = i + 1) begin : stage0
            assign sum_stage0[i]   = n_const[i] ^ shift[i] ^ (i == 0 ? 1'b1 : carry_stage0[i-1]);
            assign carry_stage0[i] = (n_const[i] & ~shift[i]) | (n_const[i] & (i == 0 ? 1'b1 : carry_stage0[i-1])) | (~shift[i] & (i == 0 ? 1'b1 : carry_stage0[i-1]));
        end
    endgenerate

    // Assign final sum as rot_shift
    assign rot_shift = sum_stage0;

    assign data_out = data_in << rot_shift;
endmodule

// -----------------------------------------------------------------------------
// Shifter Combiner Module
// Combines rotated and right-shifted outputs via bitwise OR
// -----------------------------------------------------------------------------
module shifter_combiner #(parameter N = 8) (
    input  wire [N-1:0] left_rotated,
    input  wire [N-1:0] right_shifted,
    output wire [N-1:0] out
);
    assign out = left_rotated | right_shifted;
endmodule