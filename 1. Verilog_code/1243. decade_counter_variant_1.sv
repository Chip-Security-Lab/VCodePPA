//SystemVerilog
module decade_counter (
    input wire clk, reset,
    input wire enable,  // 输入使能信号以控制流水线
    output reg [3:0] counter,
    output reg decade_pulse,
    output reg valid_out  // 指示输出数据有效
);
    // 内部信号 - 组合逻辑的结果
    wire [3:0] next_counter;
    wire next_decade_pulse;
    
    // 组合逻辑：计算下一个计数值和脉冲信号
    assign next_counter = (counter == 4'd9) ? 4'd0 : counter + 1'b1;
    assign next_decade_pulse = (counter == 4'd9) ? 1'b1 : 1'b0;
    
    // 寄存器更新逻辑 - 前向重定时后的实现
    always @(posedge clk) begin
        if (reset) begin
            counter <= 4'd0;
            decade_pulse <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            if (enable) begin
                // 直接寄存组合逻辑的结果
                counter <= next_counter;
                decade_pulse <= next_decade_pulse;
                valid_out <= 1'b1;
            end
            else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule