//SystemVerilog
module wave1_square_basic #(
    parameter PERIOD = 10
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    reg [$clog2(PERIOD)-1:0] cnt;
    wire [$clog2(PERIOD)-1:0] period_minus_one;
    wire [$clog2(PERIOD)-1:0] cnt_next;
    wire cnt_reset;
    
    // 使用补码加法实现减法
    assign period_minus_one = PERIOD - 1;
    
    // 使用比较器检测计数器是否达到周期
    assign cnt_reset = (cnt == period_minus_one);
    
    // 显式多路复用器结构，替代三元表达式
    wire [$clog2(PERIOD)-1:0] cnt_plus_one;
    wire [$clog2(PERIOD)-1:0] cnt_zero;
    
    assign cnt_plus_one = cnt + 1'b1;
    assign cnt_zero = {$clog2(PERIOD){1'b0}};
    
    // 使用显式的多路复用器选择下一个计数值
    assign cnt_next = cnt_reset ? cnt_zero : cnt_plus_one;

    // 输出波形逻辑
    wire wave_out_next;
    wire wave_out_toggle;
    
    assign wave_out_toggle = ~wave_out;
    assign wave_out_next = cnt_reset ? wave_out_toggle : wave_out;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= cnt_zero;
            wave_out <= 1'b0;
        end else begin
            cnt <= cnt_next;
            wave_out <= wave_out_next;
        end
    end
endmodule