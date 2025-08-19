//SystemVerilog
// Top level module
module async_right_logical_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);

    // Instantiate shift operation module
    shift_operation #(
        .WIDTH(WIDTH)
    ) shift_op (
        .in_data(in_data),
        .shift_amt(shift_amt),
        .out_data(out_data)
    );

    // Verification code
    // synthesis translate_off
    initial begin
        $display("Async Right Logical Shifter, Width=%0d", WIDTH);
    end
    // synthesis translate_on

endmodule

// Shift operation submodule
module shift_operation #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);

    // Pure combinational implementation
    assign out_data = in_data >> shift_amt;

endmodule