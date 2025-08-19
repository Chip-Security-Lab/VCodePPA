//SystemVerilog
// Optimized Hierarchical Barrel Shifter Design

// -----------------------------------------------------------------------------
// Top-level Module: barrel_shifter
// Function: Performs logical barrel shift (left and right) and combines result
// -----------------------------------------------------------------------------
module barrel_shifter #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_in,
    input  [2:0]       shift_amt,
    output [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] left_shift_result;
    wire [WIDTH-1:0] right_shift_result;

    barrel_left_shifter #(.WIDTH(WIDTH)) u_left_shifter (
        .data_in(data_in),
        .shift_amt(shift_amt),
        .data_out(left_shift_result)
    );

    barrel_right_shifter #(.WIDTH(WIDTH)) u_right_shifter (
        .data_in(data_in),
        .shift_amt(shift_amt),
        .data_out(right_shift_result)
    );

    barrel_shift_combiner #(.WIDTH(WIDTH)) u_shift_combiner (
        .left_shifted(left_shift_result),
        .right_shifted(right_shift_result),
        .data_out(data_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: barrel_left_shifter
// Function: Parameterized logical left shifter (optimized using multiplexers)
// -----------------------------------------------------------------------------
module barrel_left_shifter #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_in,
    input  [2:0]       shift_amt,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] stage0, stage1, stage2;

    // Stage 0: Shift by 1 if shift_amt[0]
    assign stage0 = shift_amt[0] ? {data_in[WIDTH-2:0], 1'b0} : data_in;
    // Stage 1: Shift by 2 if shift_amt[1]
    assign stage1 = shift_amt[1] ? {stage0[WIDTH-3:0], 2'b00} : stage0;
    // Stage 2: Shift by 4 if shift_amt[2]
    assign stage2 = shift_amt[2] ? {stage1[WIDTH-5:0], 4'b0000} : stage1;

    assign data_out = stage2;
endmodule

// -----------------------------------------------------------------------------
// Submodule: barrel_right_shifter
// Function: Parameterized logical right shifter (optimized using multiplexers)
// -----------------------------------------------------------------------------
module barrel_right_shifter #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_in,
    input  [2:0]       shift_amt,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] stage0, stage1, stage2;

    // Stage 0: Shift by 1 if shift_amt[0]
    assign stage0 = shift_amt[0] ? {1'b0, data_in[WIDTH-1:1]} : data_in;
    // Stage 1: Shift by 2 if shift_amt[1]
    assign stage1 = shift_amt[1] ? {2'b00, stage0[WIDTH-1:2]} : stage0;
    // Stage 2: Shift by 4 if shift_amt[2]
    assign stage2 = shift_amt[2] ? {4'b0000, stage1[WIDTH-1:4]} : stage1;

    assign data_out = stage2;
endmodule

// -----------------------------------------------------------------------------
// Submodule: barrel_shift_combiner
// Function: Bitwise OR of left and right shifted results (optimized)
// -----------------------------------------------------------------------------
module barrel_shift_combiner #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] left_shifted,
    input  [WIDTH-1:0] right_shifted,
    output [WIDTH-1:0] data_out
);
    // Simplified using consensus theorem: A | (A & B) = A | B
    assign data_out = left_shifted ^ right_shifted | left_shifted & right_shifted;
endmodule