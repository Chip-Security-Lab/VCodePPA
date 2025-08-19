//SystemVerilog
// Top-level module: shift_arith_log_sel
// Function: Selects between arithmetic and logical right shift based on 'mode'

module shift_arith_log_sel #(
    parameter WIDTH = 8
) (
    input  wire             mode,   // 0: logical, 1: arithmetic
    input  wire [WIDTH-1:0] din,
    input  wire [2:0]       shift,
    output wire [WIDTH-1:0] dout
);

    // Directly instantiate shift logic, combine selection with optimized logic
    wire [WIDTH-1:0] arith_shift_result;
    wire [WIDTH-1:0] logic_shift_result;

    shift_arith #(.WIDTH(WIDTH)) u_shift_arith (
        .din   (din),
        .shift (shift),
        .dout  (arith_shift_result)
    );

    shift_log #(.WIDTH(WIDTH)) u_shift_log (
        .din   (din),
        .shift (shift),
        .dout  (logic_shift_result)
    );

    // Optimized selection: Use ternary operator to avoid extra register logic
    assign dout = mode ? arith_shift_result : logic_shift_result;

endmodule

// -----------------------------------------------------------------------------
// Arithmetic Right Shift Module
// Performs signed arithmetic right shift
// -----------------------------------------------------------------------------
module shift_arith #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] din,
    input  wire [2:0]       shift,
    output wire [WIDTH-1:0] dout
);

    // Efficient arithmetic shift: Only apply sign extension if shift is nonzero
    wire signed [WIDTH-1:0]      din_signed = din;
    wire [$clog2(WIDTH):0]       shift_amt  = (shift < WIDTH) ? shift : WIDTH;

    assign dout = (shift_amt == 0) ? din :
                  (shift_amt >= WIDTH) ? {WIDTH{din[WIDTH-1]}} :
                  din_signed >>> shift_amt;

endmodule

// -----------------------------------------------------------------------------
// Logical Right Shift Module
// Performs unsigned logical right shift
// -----------------------------------------------------------------------------
module shift_log #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] din,
    input  wire [2:0]       shift,
    output wire [WIDTH-1:0] dout
);

    // Efficient logical shift: Handle shift width overflows
    wire [$clog2(WIDTH):0] shift_amt = (shift < WIDTH) ? shift : WIDTH;

    assign dout = (shift_amt == 0) ? din :
                  (shift_amt >= WIDTH) ? {WIDTH{1'b0}} :
                  din >> shift_amt;

endmodule