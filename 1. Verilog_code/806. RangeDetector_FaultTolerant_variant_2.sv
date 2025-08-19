//SystemVerilog
module RangeDetector_FaultTolerant #(
    parameter WIDTH = 8,
    parameter TOLERANCE = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] low_th,
    input [WIDTH-1:0] high_th,
    output reg alarm
);
reg [1:0] err_count;
wire below_th, above_th;
wire [1:0] err_count_inc, err_count_dec;
wire [1:0] err_count_next;
wire borrow_bit;

// 条件求和减法算法实现
assign below_th = (data_in < low_th);
assign above_th = (data_in > high_th);

// 计算增加错误计数的条件
assign err_count_inc = (err_count < TOLERANCE) ? err_count + 1'b1 : TOLERANCE;

// 使用条件求和减法算法实现减法
assign borrow_bit = (err_count[0] < 1'b1);
assign err_count_dec[0] = err_count[0] ^ 1'b1; // 按位异或实现减法的低位
assign err_count_dec[1] = err_count[1] ^ borrow_bit; // 考虑借位的高位减法

// 选择下一个错误计数值
assign err_count_next = (below_th || above_th) ? err_count_inc : 
                        (err_count > 0) ? err_count_dec : 2'b00;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        err_count <= 2'b00;
        alarm <= 1'b0;
    end
    else begin
        err_count <= err_count_next;
        alarm <= (err_count_next == TOLERANCE);
    end
end
endmodule