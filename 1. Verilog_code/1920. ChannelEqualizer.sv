module ChannelEqualizer #(parameter WIDTH=8) (
    input clk,
    input signed [WIDTH-1:0] rx_sample,
    output reg [WIDTH-1:0] eq_output
);
    reg signed [WIDTH-1:0] taps [0:4];
    integer i;
    wire signed [WIDTH+3:0] eq_sum;  // 更宽以容纳和
    
    always @(posedge clk) begin
        // 修复错误的数组赋值
        for (i = 4; i > 0; i = i - 1) begin
            taps[i] <= taps[i-1];
        end
        taps[0] <= rx_sample;
    end
    
    // 计算均衡输出
    assign eq_sum = (taps[0] * (-1) + taps[1] * 3 + taps[2] * 3 + taps[3] * (-1));
    
    always @(posedge clk) begin
        eq_output <= eq_sum >>> 2;  // 算术右移
    end
endmodule