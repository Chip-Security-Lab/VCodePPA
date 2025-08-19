//SystemVerilog
module reset_pulse_stretch #(
    parameter STRETCH_COUNT = 4
)(
    input wire clk,
    input wire reset_in,
    output reg reset_out
);
    // 使用标准宽度以匹配STRETCH_COUNT的要求
    reg [2:0] counter;
    
    always @(posedge clk) begin
        if (reset_in) begin
            // 重置计数器并激活输出
            counter <= STRETCH_COUNT;
            reset_out <= 1'b1;
        end else if (|counter) begin
            // 当计数器不为零时递减
            counter <= counter - 1'b1;
            reset_out <= 1'b1;
        end else begin
            // 计数器为零时关闭输出
            reset_out <= 1'b0;
        end
    end
endmodule