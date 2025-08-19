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
    reg [WIDTH-1:0] counter_buf1, counter_buf2;
    wire compare_period, compare_pulse;

    // 分离比较逻辑，减少counter扇出
    assign compare_period = (counter < period-1);
    assign compare_pulse = (counter_buf1 < pulse_width);
    
    always @(posedge clk) begin
        // 计数器逻辑
        if (compare_period)
            counter <= counter + 1;
        else
            counter <= 0;
            
        // 缓冲寄存器，减少counter的扇出负载
        counter_buf1 <= counter;
        counter_buf2 <= counter_buf1;
        
        // 使用缓冲后的counter进行脉冲生成
        pulse <= compare_pulse ? 1'b1 : 1'b0;
    end
endmodule