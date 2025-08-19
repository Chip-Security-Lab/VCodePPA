//SystemVerilog
module divider_16bit_top (
    input [15:0] dividend,
    input [15:0] divisor,
    output [15:0] quotient,
    output [15:0] remainder
);

    // 实例化除法运算子模块
    divider_core #(
        .WIDTH(16)
    ) div_core_inst (
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

module divider_core #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    output reg [WIDTH-1:0] quotient,
    output reg [WIDTH-1:0] remainder
);

    // 内部信号
    wire [WIDTH-1:0] div_result;
    wire [WIDTH-1:0] rem_result;
    
    // 实例化运算单元
    division_unit #(
        .WIDTH(WIDTH)
    ) div_unit (
        .dividend(dividend),
        .divisor(divisor),
        .quotient(div_result),
        .remainder(rem_result)
    );
    
    // 寄存结果
    always @(*) begin
        quotient <= div_result;
        remainder <= rem_result;
    end

endmodule

module division_unit #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    output [WIDTH-1:0] quotient,
    output [WIDTH-1:0] remainder
);

    // 除法运算逻辑
    assign quotient = dividend / divisor;
    assign remainder = dividend % divisor;

endmodule