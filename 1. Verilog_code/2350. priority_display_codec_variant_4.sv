//SystemVerilog
module priority_display_codec (
    input clk, rst_n,
    input [23:0] rgb_data,
    input [7:0] mono_data,
    input [15:0] yuv_data,
    input [2:0] format_select, // 0:RGB, 1:MONO, 2:YUV, 3-7:Reserved
    input priority_override,  // High priority mode
    output reg [15:0] display_out,
    output reg format_valid
);
    // 预计算RGB565格式
    reg [15:0] rgb565_data_reg;
    reg [15:0] mono16_data_reg;
    reg [15:0] yuv_data_reg;
    reg [2:0] format_select_reg;
    reg priority_override_reg;
    
    // 第一级：输入寄存器阶段 - 捕获所有输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_data_reg <= 16'h0000;
            mono16_data_reg <= 16'h0000;
            yuv_data_reg <= 16'h0000;
            format_select_reg <= 3'b000;
            priority_override_reg <= 1'b0;
        end else begin
            rgb565_data_reg <= {rgb_data[23:19], rgb_data[15:10], rgb_data[7:3]};
            mono16_data_reg <= {mono_data, mono_data};
            yuv_data_reg <= yuv_data;
            format_select_reg <= format_select;
            priority_override_reg <= priority_override;
        end
    end
    
    // 第二级：输出逻辑阶段
    reg [2:0] active_fmt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out <= 16'h0000;
            format_valid <= 1'b0;
            active_fmt <= 3'b000;
        end else begin
            active_fmt <= priority_override_reg ? 3'b000 : format_select_reg;
            
            case (active_fmt)
                3'b000: begin // RGB模式
                    display_out <= rgb565_data_reg;
                    format_valid <= 1'b1;
                end
                3'b001: begin // 单色模式
                    display_out <= mono16_data_reg;
                    format_valid <= 1'b1;
                end
                3'b010: begin // YUV模式
                    display_out <= yuv_data_reg;
                    format_valid <= 1'b1;
                end
                default: begin // 无效格式：3'b011到3'b111
                    display_out <= 16'h0000;
                    format_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule