//SystemVerilog
module rgb_async_convert (
    input wire clk,
    input wire rst_n,
    input wire [23:0] rgb888,
    input wire valid_in,
    output reg [15:0] rgb565,
    output reg valid_out
);

    // 第一级流水线 - 提取RGB通道
    reg [4:0] r_channel_s1;
    reg [5:0] g_channel_s1;
    reg [4:0] b_channel_s1;
    reg valid_s1;

    // 第二级流水线 - 重组为RGB565格式
    reg [15:0] rgb565_s2;
    reg valid_s2;

    // 第一级流水线处理 - 通道提取
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_channel_s1 <= 5'b0;
            g_channel_s1 <= 6'b0;
            b_channel_s1 <= 5'b0;
            valid_s1 <= 1'b0;
        end else begin
            r_channel_s1 <= rgb888[23:19];  // 从RGB888提取红色分量
            g_channel_s1 <= rgb888[15:10];  // 从RGB888提取绿色分量
            b_channel_s1 <= rgb888[7:3];    // 从RGB888提取蓝色分量
            valid_s1 <= valid_in;
        end
    end

    // 第二级流水线处理 - 通道合并
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_s2 <= 16'b0;
            valid_s2 <= 1'b0;
        end else begin
            rgb565_s2 <= {r_channel_s1, g_channel_s1, b_channel_s1};  // 组合为RGB565格式
            valid_s2 <= valid_s1;
        end
    end

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565 <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            rgb565 <= rgb565_s2;
            valid_out <= valid_s2;
        end
    end

endmodule