//SystemVerilog
module divider_error_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg error
);

// 使用独立的零检测逻辑，可以减少关键路径延迟
wire divisor_is_zero = ~|divisor;

always @(*) begin
    // 使用更高效的零检测信号
    error = divisor_is_zero;
    
    // 将条件运算符转换为if-else结构以提高可读性
    if (divisor_is_zero) begin
        quotient = 8'b0;
        remainder = 8'b0;
    end else begin
        quotient = dividend / divisor;
        remainder = dividend % divisor;
    end
end

endmodule