//SystemVerilog
module gamma_correction_codec (
    input clk, enable, reset,
    input [7:0] pixel_in,
    input [2:0] gamma_factor,
    output reg [7:0] pixel_out
);
    // 查找表定义
    reg [15:0] gamma_lut [0:7][0:255];
    
    // 后向寄存器重定时优化：将计算寄存到pipeline中
    reg [7:0] pixel_in_reg;
    reg [2:0] gamma_factor_reg;
    reg enable_reg;
    
    // 扇出缓冲寄存器
    reg [2:0] g_buf1, g_buf2;
    reg [7:0] i_buf1, i_buf2;
    
    integer g, i;
    
    // 初始化查找表
    initial begin
        // 使用缓冲的g变量减少扇出
        for (g = 0; g < 8; g = g + 1) begin
            g_buf1 = g;
            g_buf2 = g;
            for (i = 0; i < 256; i = i + 1) begin
                i_buf1 = i;
                i_buf2 = i;
                gamma_lut[g_buf1][i_buf1] = i_buf2 * (g_buf2 + 1);
            end
        end
    end
    
    // 第一级流水线：捕获输入
    always @(posedge clk) begin
        if (reset) begin
            pixel_in_reg <= 8'd0;
            gamma_factor_reg <= 3'd0;
            enable_reg <= 1'b0;
        end else begin
            pixel_in_reg <= pixel_in;
            gamma_factor_reg <= gamma_factor;
            enable_reg <= enable;
        end
    end
    
    // 添加中间缓冲寄存器减少扇出负载
    reg [2:0] gamma_factor_buf;
    reg [7:0] pixel_in_buf;
    reg enable_buf;
    reg [15:0] lut_value;
    
    always @(posedge clk) begin
        if (reset) begin
            gamma_factor_buf <= 3'd0;
            pixel_in_buf <= 8'd0;
            enable_buf <= 1'b0;
            lut_value <= 16'd0;
        end else begin
            gamma_factor_buf <= gamma_factor_reg;
            pixel_in_buf <= pixel_in_reg;
            enable_buf <= enable_reg;
            // 预先读取查找表值，分散负载
            lut_value <= gamma_lut[gamma_factor_reg][pixel_in_reg];
        end
    end
    
    // 第二级流水线：查表并输出
    always @(posedge clk) begin
        if (reset)
            pixel_out <= 8'd0;
        else if (enable_buf)
            pixel_out <= lut_value[7:0];
    end
endmodule