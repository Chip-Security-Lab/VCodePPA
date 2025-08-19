//SystemVerilog
module reset_pulse_stretch #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire reset_in,
    output reg  reset_out
);
    // 重新设计的复位逻辑
    reg [2:0] counter;
    reg reset_detected;
    
    always @(posedge clk) begin
        // 检测复位信号变化
        reset_detected <= reset_in;
        
        // 优化的计数器处理逻辑
        if (reset_in) begin
            // 复位信号激活时重新加载计数器
            counter <= STRETCH_COUNT;
            reset_out <= 1'b1;
        end
        else if (|counter) begin
            // 使用归约操作符检查计数器非零情况，更高效
            counter <= counter - 1'b1;
            reset_out <= 1'b1;
        end
        else begin
            // 计数器为零，复位信号结束
            reset_out <= 1'b0;
        end
    end
endmodule