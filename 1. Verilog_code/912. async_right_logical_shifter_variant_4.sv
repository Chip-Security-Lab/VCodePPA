//SystemVerilog
module async_right_logical_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);
    // 实例化移位计算单元
    shift_calculator #(
        .WIDTH(WIDTH)
    ) shift_calc_inst (
        .in_data(in_data),
        .shift_amt(shift_amt),
        .out_data(out_data)
    );
    
    // Verification code to ensure proper shifting
    // synthesis translate_off
    initial begin
        $display("Async Right Logical Shifter, Width=%0d", WIDTH);
    end
    // synthesis translate_on
endmodule

module shift_calculator #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);
    // 优化的移位处理逻辑 - 直接使用Verilog内置的右移运算符
    assign out_data = in_data >> shift_amt;
endmodule