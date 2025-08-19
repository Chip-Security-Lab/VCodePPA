//SystemVerilog
// SystemVerilog
module async_rgb565_codec (
    input wire [23:0] rgb_in,    // 24-bit RGB输入
    input wire alpha_en,         // Alpha通道使能信号
    output reg [15:0] rgb565_out // 16-bit RGB565输出
);

    // 分段提取RGB通道数据
    reg [4:0] red_channel;
    reg [5:0] green_channel;
    reg [4:0] blue_channel;
    
    // 红色通道数据提取
    always @(*) begin
        red_channel = rgb_in[23:19];
    end
    
    // 绿色通道数据提取
    always @(*) begin
        green_channel = rgb_in[15:10];
    end
    
    // 蓝色通道数据提取
    always @(*) begin
        blue_channel = rgb_in[7:3];
    end
    
    // Alpha处理与RGB565格式组装
    always @(*) begin
        if (alpha_en) begin
            // 当Alpha使能时，设置最高位为1
            rgb565_out[15] = 1'b1;
        end else begin
            // 当Alpha禁用时，保持原RGB数据
            rgb565_out[15] = red_channel[4];
        end
        
        // 组装剩余的RGB通道数据
        rgb565_out[14:11] = red_channel[3:0];
        rgb565_out[10:5] = green_channel;
        rgb565_out[4:0] = blue_channel;
    end

endmodule