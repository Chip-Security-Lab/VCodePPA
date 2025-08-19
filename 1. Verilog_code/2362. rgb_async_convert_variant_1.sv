//SystemVerilog
module rgb_async_convert (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 复位信号，低电平有效
    input wire [23:0] rgb888, // 24位RGB888输入
    input wire data_valid_in, // 输入数据有效信号
    output reg [15:0] rgb565, // 16位RGB565输出
    output reg data_valid_out // 输出数据有效信号
);

    // 流水线阶段1: 提取各个颜色通道并进行初步转换
    reg [7:0] r_channel_in;   // 红色通道寄存器
    reg [7:0] g_channel_in;   // 绿色通道寄存器
    reg [7:0] b_channel_in;   // 蓝色通道寄存器
    reg valid_s1;             // 阶段1有效标志
    
    // 流水线阶段2: 颜色通道转换中间结果
    reg [4:0] r_channel_s2;   // 红色通道转换结果
    reg [5:0] g_channel_s2;   // 绿色通道转换结果
    reg [4:0] b_channel_s2;   // 蓝色通道转换结果
    reg valid_s2;             // 阶段2有效标志
    
    // 流水线阶段3: 高位部分预处理
    reg [10:0] rgb_high_part; // RGB高11位预处理
    reg [4:0] b_channel_s3;   // 蓝色通道保存
    reg valid_s3;             // 阶段3有效标志

    // 阶段1: 颜色通道提取和寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_channel_in <= 8'b0;
            g_channel_in <= 8'b0;
            b_channel_in <= 8'b0;
            valid_s1 <= 1'b0;
        end else begin
            r_channel_in <= rgb888[23:16];
            g_channel_in <= rgb888[15:8];
            b_channel_in <= rgb888[7:0];
            valid_s1 <= data_valid_in;
        end
    end

    // 阶段2: 颜色通道处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_channel_s2 <= 5'b0;
            g_channel_s2 <= 6'b0;
            b_channel_s2 <= 5'b0;
            valid_s2 <= 1'b0;
        end else begin
            // 分段处理各通道，减少每个时钟周期的组合逻辑延迟
            r_channel_s2 <= r_channel_in[7:3]; // 取红色高5位
            g_channel_s2 <= g_channel_in[7:2]; // 取绿色高6位
            b_channel_s2 <= b_channel_in[7:3]; // 取蓝色高5位
            valid_s2 <= valid_s1;
        end
    end

    // 阶段3: 部分拼接，减少最后阶段的组合逻辑延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_high_part <= 11'b0;
            b_channel_s3 <= 5'b0;
            valid_s3 <= 1'b0;
        end else begin
            // 预先拼接RGB高11位，将组合拼接分成两部分
            rgb_high_part <= {r_channel_s2, g_channel_s2};
            b_channel_s3 <= b_channel_s2;
            valid_s3 <= valid_s2;
        end
    end

    // 阶段4: 最终拼接输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565 <= 16'b0;
            data_valid_out <= 1'b0;
        end else begin
            // 最终拼接，只需要组合rgb_high_part和b_channel_s3
            rgb565 <= {rgb_high_part, b_channel_s3};
            data_valid_out <= valid_s3;
        end
    end

endmodule