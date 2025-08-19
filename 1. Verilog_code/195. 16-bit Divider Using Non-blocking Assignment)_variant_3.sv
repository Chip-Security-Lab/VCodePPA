//SystemVerilog
// 顶层模块
module divider_16bit_nba (
    input [15:0] dividend,
    input [15:0] divisor,
    output [15:0] quotient,
    output [15:0] remainder
);

    // 参数定义
    parameter WIDTH = 16;
    
    // 内部信号
    wire division_valid;
    
    // 零检测子模块实例化
    zero_detector #(
        .WIDTH(WIDTH)
    ) u_zero_detector (
        .divisor(divisor),
        .division_valid(division_valid)
    );
    
    // 除法运算子模块实例化
    division_unit #(
        .WIDTH(WIDTH)
    ) u_division_unit (
        .dividend(dividend),
        .divisor(divisor),
        .division_valid(division_valid),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

// 零检测子模块
module zero_detector #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] divisor,
    output division_valid
);

    // 当除数不为零时，除法操作有效
    assign division_valid = |divisor;

endmodule

// 除法运算子模块
module division_unit #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    input division_valid,
    output reg [WIDTH-1:0] quotient,
    output reg [WIDTH-1:0] remainder
);

    // 执行除法运算
    always @(*) begin
        if (division_valid) begin
            quotient = dividend / divisor;
            remainder = dividend % divisor;
        end
        else begin
            // 处理除数为0的情况
            quotient = {WIDTH{1'b1}}; // 全1表示错误
            remainder = dividend;     // 保留被除数
        end
    end

endmodule