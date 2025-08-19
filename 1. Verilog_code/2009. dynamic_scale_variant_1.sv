//SystemVerilog
// Top-level module: dynamic_scale
// Function: Dynamically shifts the input left or right based on the sign and magnitude of 'shift'.
// Hierarchical decomposition into direction decode and shifter submodules.

module dynamic_scale #(
    parameter W = 24
)(
    input  wire [W-1:0] in,
    input  wire [4:0]   shift,
    output wire [W-1:0] out
);

    wire        shift_left;
    wire [3:0]  abs_shift_amount;
    wire [W-1:0] shifted_result;

    // Submodule: shift_direction_decode
    shift_direction_decode u_shift_direction_decode (
        .shift_in      (shift),
        .shift_left    (shift_left),
        .abs_shift_amount  (abs_shift_amount)
    );

    // Submodule: variable_shifter
    variable_shifter #(
        .W(W)
    ) u_variable_shifter (
        .data_in       (in),
        .shift_left    (shift_left),
        .shift_amount  (abs_shift_amount),
        .data_out      (shifted_result)
    );

    assign out = shifted_result;

endmodule

// Submodule: shift_direction_decode
// Purpose: Decodes the shift direction (left/right) and shift amount (absolute value) using two's complement addition for subtraction.
module shift_direction_decode (
    input  wire [4:0] shift_in,
    output wire       shift_left,
    output wire [3:0] abs_shift_amount
);
    wire [3:0] shift_magnitude_inverted;
    wire [3:0] shift_magnitude_twos_complement;

    // shift_left is high if the sign bit (MSB) is 1 (negative, left shift)
    assign shift_left = shift_in[4];

    // Compute two's complement of shift_in[3:0] using bitwise inversion and addition
    assign shift_magnitude_inverted = ~shift_in[3:0];
    assign shift_magnitude_twos_complement = shift_magnitude_inverted + 4'b0001;

    // abs_shift_amount is the absolute value of shift_in[3:0] using two's complement addition
    assign abs_shift_amount = shift_in[4] ? shift_magnitude_twos_complement : shift_in[3:0];
endmodule

// Submodule: variable_shifter
// Purpose: Performs left or right shift on input data by a variable amount.
// Parameterized by data width W.
module variable_shifter #(
    parameter W = 24
)(
    input  wire [W-1:0] data_in,
    input  wire         shift_left,
    input  wire [3:0]   shift_amount,
    output wire [W-1:0] data_out
);
    wire [W-1:0] left_shifted_result;
    wire [W-1:0] right_shifted_result;

    assign left_shifted_result  = data_in << shift_amount;
    assign right_shifted_result = data_in >> shift_amount;
    assign data_out             = shift_left ? left_shifted_result : right_shifted_result;
endmodule