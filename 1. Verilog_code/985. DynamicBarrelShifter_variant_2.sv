//SystemVerilog
module DynamicBarrelShifter #(parameter MAX_SHIFT = 4, WIDTH = 8) (
    input  [WIDTH-1:0] data_in,
    input  [MAX_SHIFT-1:0] shift_val,
    output [WIDTH-1:0] data_out,
    output [MAX_SHIFT-1:0] shift_diff
);

    wire [MAX_SHIFT-1:0] shift_val_neg;
    wire                 carry_out;

    // Use two's complement addition to perform subtraction: (data_in << shift_val) - shift_val
    // Compute two's complement of shift_val for subtraction
    assign shift_val_neg = (~shift_val) + 1'b1;

    // data_out: shifted data
    assign data_out = data_in << shift_val;

    // shift_diff: (shift_val) - shift_val (should be zero, demonstration of two's complement subtraction)
    // Example: result = shift_val + (~shift_val + 1)
    assign {carry_out, shift_diff} = shift_val + shift_val_neg;

endmodule