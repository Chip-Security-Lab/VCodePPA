//SystemVerilog
module param_square_wave #(
    parameter WIDTH = 16
)(
    input clock_i,
    input reset_i,
    input [WIDTH-1:0] period_i,
    input [WIDTH-1:0] duty_i,
    output reg wave_o
);
    reg [WIDTH-1:0] counter_r;
    wire period_end;
    
    // 使用专用比较信号提前计算周期结束条件
    assign period_end = (counter_r >= period_i - 1'b1);
    
    always @(posedge clock_i) begin
        if (reset_i)
            counter_r <= {WIDTH{1'b0}};
        else if (period_end)
            counter_r <= {WIDTH{1'b0}};
        else
            counter_r <= counter_r + 1'b1;
    end
    
    // 将组合逻辑输出转换为寄存器输出，减少毛刺风险
    always @(posedge clock_i) begin
        if (reset_i)
            wave_o <= 1'b0;
        else
            wave_o <= (counter_r < duty_i);
    end
endmodule