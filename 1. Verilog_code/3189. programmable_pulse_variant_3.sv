//SystemVerilog
module programmable_pulse #(
    parameter WIDTH = 16
)(
    input clk,
    input [WIDTH-1:0] period,
    input [WIDTH-1:0] pulse_width,
    output reg pulse
);
    reg [WIDTH-1:0] counter;
    reg [WIDTH-1:0] period_minus_one;
    reg [WIDTH-1:0] pulse_width_reg;
    reg compare_result;
    
    always @(posedge clk) begin
        // 计算period-1并寄存输入参数
        period_minus_one <= period - 1'b1;
        pulse_width_reg <= pulse_width;
        
        // 计数器逻辑和比较逻辑
        if (counter < period_minus_one)
            counter <= counter + 1'b1;
        else
            counter <= 0;
            
        compare_result <= (counter < pulse_width_reg) ? 1'b1 : 1'b0;
        
        // 输出寄存器
        pulse <= compare_result;
    end
endmodule