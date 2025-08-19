//SystemVerilog
// 顶层模块
module divider_param #(parameter WIDTH=32)(
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    output [WIDTH-1:0] quotient,
    output [WIDTH-1:0] remainder
);
    // 直接在顶层模块中计算商和余数，避免子模块实例化带来的开销
    assign quotient = divisor ? dividend / divisor : {WIDTH{1'b1}}; // 添加除零保护
    assign remainder = divisor ? dividend % divisor : dividend;      // 添加除零保护
    
endmodule