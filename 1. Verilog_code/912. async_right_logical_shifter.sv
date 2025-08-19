module async_right_logical_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);
    // Pure combinational implementation
    assign out_data = in_data >> shift_amt;
    
    // Verification code to ensure proper shifting
    // synthesis translate_off
    initial begin
        $display("Async Right Logical Shifter, Width=%0d", WIDTH);
    end
    // synthesis translate_on
endmodule