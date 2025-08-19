//SystemVerilog
module shift_mux_based #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    input  [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] shift_stage_0;
    wire [WIDTH-1:0] shift_stage_1;
    wire [WIDTH-1:0] shift_stage_2;

    // Conditional Invert Subtractor for shift amount calculation: (WIDTH-1) - shift_amt
    localparam [$clog2(WIDTH)-1:0] SHIFT_MAX = WIDTH - 1;

    wire [$clog2(WIDTH)-1:0] shift_amt_invert;
    wire [$clog2(WIDTH)-1:0] shift_amt_inv;
    wire                     subtract_carry_in;
    wire [$clog2(WIDTH)-1:0] subtract_sum;
    wire                     subtract_carry_out;

    assign shift_amt_invert = ~shift_amt;
    assign subtract_carry_in = 1'b1; // For two's complement subtraction

    // Conditional invert subtractor: result = SHIFT_MAX + (~shift_amt) + 1
    assign {subtract_carry_out, subtract_sum} = SHIFT_MAX + shift_amt_invert + subtract_carry_in;
    assign shift_amt_inv = subtract_sum;

    // 3-stage right shifter controlled by shift_amt_inv
    // Stage 0: shift by 1 if shift_amt_inv[0] == 1
    assign shift_stage_0 = shift_amt_inv[0] ? {1'b0, data_in[WIDTH-1:1]} : data_in;

    // Stage 1: shift by 2 if shift_amt_inv[1] == 1
    assign shift_stage_1 = shift_amt_inv[1] ? {2'b00, shift_stage_0[WIDTH-1:2]} : shift_stage_0;

    // Stage 2: shift by 4 if shift_amt_inv[2] == 1
    assign shift_stage_2 = shift_amt_inv[2] ? {4'b0000, shift_stage_1[WIDTH-1:4]} : shift_stage_1;

    assign data_out = shift_stage_2;

endmodule