//SystemVerilog
// Top-level barrel shifter module with hierarchical structure

module barrel_shifter (
    input  wire [7:0] data_in,        // Input data
    input  wire [2:0] shift_amt,      // Shift amount
    input  wire       direction,      // 0: right, 1: left
    output wire [7:0] shifted_out     // Shifted result
);

    wire [7:0] left_shifted;
    wire [7:0] right_shifted;

    // Left shift submodule instance (barrel shifter structure)
    left_shifter u_left_shifter (
        .data_in   (data_in),
        .shift_amt (shift_amt),
        .result    (left_shifted)
    );

    // Right shift submodule instance (barrel shifter structure)
    right_shifter u_right_shifter (
        .data_in   (data_in),
        .shift_amt (shift_amt),
        .result    (right_shifted)
    );

    // Mux submodule instance to select direction
    shift_mux u_shift_mux (
        .left_shifted  (left_shifted),
        .right_shifted (right_shifted),
        .direction     (direction),
        .shifted_out   (shifted_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Left shifter: Performs left logical shift operation using barrel shifter structure
// -----------------------------------------------------------------------------
module left_shifter (
    input  wire [7:0] data_in,         // Data to be shifted
    input  wire [2:0] shift_amt,       // Shift amount
    output wire [7:0] result           // Left-shifted result
);
    wire [7:0] stage0;
    wire [7:0] stage1;
    wire [7:0] stage2;

    // Stage 0: shift by 1 if shift_amt[0] is set
    assign stage0 = shift_amt[0] ? {data_in[6:0], 1'b0} : data_in;
    // Stage 1: shift by 2 if shift_amt[1] is set
    assign stage1 = shift_amt[1] ? {stage0[5:0], 2'b00} : stage0;
    // Stage 2: shift by 4 if shift_amt[2] is set
    assign stage2 = shift_amt[2] ? {stage1[3:0], 4'b0000} : stage1;

    assign result = stage2;
endmodule

// -----------------------------------------------------------------------------
// Right shifter: Performs right logical shift operation using barrel shifter structure
// -----------------------------------------------------------------------------
module right_shifter (
    input  wire [7:0] data_in,         // Data to be shifted
    input  wire [2:0] shift_amt,       // Shift amount
    output wire [7:0] result           // Right-shifted result
);
    wire [7:0] stage0;
    wire [7:0] stage1;
    wire [7:0] stage2;

    // Stage 0: shift by 1 if shift_amt[0] is set
    assign stage0 = shift_amt[0] ? {1'b0, data_in[7:1]} : data_in;
    // Stage 1: shift by 2 if shift_amt[1] is set
    assign stage1 = shift_amt[1] ? {2'b00, stage0[7:2]} : stage0;
    // Stage 2: shift by 4 if shift_amt[2] is set
    assign stage2 = shift_amt[2] ? {4'b0000, stage1[7:4]} : stage1;

    assign result = stage2;
endmodule

// -----------------------------------------------------------------------------
// Shift mux: Selects left or right shifted result based on direction
// -----------------------------------------------------------------------------
module shift_mux (
    input  wire [7:0] left_shifted,    // Output from left shifter
    input  wire [7:0] right_shifted,   // Output from right shifter
    input  wire       direction,       // 0: right, 1: left
    output wire [7:0] shifted_out      // Selected shift result
);
    assign shifted_out = direction ? left_shifted : right_shifted;
endmodule