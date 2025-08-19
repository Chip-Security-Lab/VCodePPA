//SystemVerilog
module priority_display_codec (
    input clk, rst_n,
    input [23:0] rgb_data,
    input [7:0] mono_data,
    input [15:0] yuv_data,
    input [2:0] format_select, // 0:RGB, 1:MONO, 2:YUV, 3-7:Reserved
    input priority_override,   // High priority mode
    output reg [15:0] display_out,
    output reg format_valid
);
    // 直接计算格式转换，无需等待时钟
    wire [15:0] rgb_converted_w = {rgb_data[23:19], rgb_data[15:10], rgb_data[7:3]};
    wire [15:0] mono_converted_w = {mono_data, mono_data};
    wire [15:0] yuv_converted_w = yuv_data;
    
    // 格式选择信号
    reg [2:0] format_select_r;
    reg priority_override_r;
    reg [2:0] active_fmt_r;
    
    // 数据管道寄存器
    reg [15:0] selected_data;
    reg data_valid_r;
    
    // 注册输入控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            format_select_r <= 3'b000;
            priority_override_r <= 1'b0;
        end else begin
            format_select_r <= format_select;
            priority_override_r <= priority_override;
        end
    end
    
    // 确定活动格式
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_fmt_r <= 3'b000;
        end else begin
            active_fmt_r <= priority_override_r ? 3'b000 : format_select_r;
        end
    end
    
    // 基于活动格式选择数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_data <= 16'h0000;
            data_valid_r <= 1'b0;
        end else begin
            case (active_fmt_r)
                3'b000: begin // RGB模式
                    selected_data <= rgb_converted_w;
                    data_valid_r <= 1'b1;
                end
                3'b001: begin // 单色模式
                    selected_data <= mono_converted_w;
                    data_valid_r <= 1'b1;
                end
                3'b010: begin // YUV模式
                    selected_data <= yuv_converted_w;
                    data_valid_r <= 1'b1;
                end
                default: begin // 无效格式
                    selected_data <= 16'h0000;
                    data_valid_r <= 1'b0;
                end
            endcase
        end
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out <= 16'h0000;
            format_valid <= 1'b0;
        end else begin
            display_out <= selected_data;
            format_valid <= data_valid_r;
        end
    end
endmodule