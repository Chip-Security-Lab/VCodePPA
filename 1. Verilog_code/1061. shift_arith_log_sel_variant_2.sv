//SystemVerilog
// Top-Level Module: shift_arith_log_sel
// Function: Selects between arithmetic and logical right shift using hierarchical structure

module shift_arith_log_sel #(
    parameter WIDTH = 8
)(
    input                  mode,    // 0: logical, 1: arithmetic
    input  [WIDTH-1:0]     din,
    input  [2:0]           shift,
    output [WIDTH-1:0]     dout
);

    // Internal signals for inter-module connections
    wire [WIDTH-1:0] shift_result_logical;
    wire [WIDTH-1:0] shift_result_arith;

    // Logical right shifter instance
    logical_right_shifter #(
        .WIDTH(WIDTH)
    ) u_logical_shifter (
        .in_data(din),
        .shift_amount(shift),
        .out_data(shift_result_logical)
    );

    // Arithmetic right shifter instance
    arithmetic_right_shifter #(
        .WIDTH(WIDTH)
    ) u_arithmetic_shifter (
        .in_data(din),
        .shift_amount(shift),
        .out_data(shift_result_arith)
    );

    // Shift result selector instance
    shift_result_mux #(
        .WIDTH(WIDTH)
    ) u_shift_result_mux (
        .sel_mode(mode),
        .in_logical(shift_result_logical),
        .in_arith(shift_result_arith),
        .out_result(dout)
    );

endmodule

// ------------------------------------------------------
// Submodule: logical_right_shifter
// Function: Performs parameterized logical right shift
// ------------------------------------------------------
module logical_right_shifter #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] in_data,
    input  [2:0]       shift_amount,
    output [WIDTH-1:0] out_data
);
    // Combinatorial logical right shift
    assign out_data = in_data >> shift_amount;
endmodule

// ------------------------------------------------------
// Submodule: arithmetic_right_shifter
// Function: Performs parameterized arithmetic right shift
// ------------------------------------------------------
module arithmetic_right_shifter #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] in_data,
    input  [2:0]       shift_amount,
    output [WIDTH-1:0] out_data
);
    // Combinatorial arithmetic right shift (sign-extended)
    assign out_data = $signed(in_data) >>> shift_amount;
endmodule

// ------------------------------------------------------
// Submodule: shift_result_mux
// Function: Selects between logical and arithmetic shift results
// ------------------------------------------------------
module shift_result_mux #(
    parameter WIDTH = 8
)(
    input                  sel_mode,     // 0: logical, 1: arithmetic
    input  [WIDTH-1:0]     in_logical,
    input  [WIDTH-1:0]     in_arith,
    output [WIDTH-1:0]     out_result
);
    // Combinatorial selection of shift result based on mode
    assign out_result = sel_mode ? in_arith : in_logical;
endmodule