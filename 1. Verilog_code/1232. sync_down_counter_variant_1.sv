//SystemVerilog
module sync_down_counter #(parameter WIDTH = 8) (
    input wire clk, rst, enable,
    output reg [WIDTH-1:0] q_out
);
    // 定义查找表
    reg [WIDTH-1:0] subtraction_lut[255:0];
    
    // 索引i的缓冲寄存器，用于减少扇出负载
    reg [7:0] i_buf1, i_buf2, i_buf3, i_buf4;
    
    // 初始化查找表
    integer i;
    initial begin
        // 将查找表初始化分为四个部分，降低单一循环变量i的扇出负载
        for (i = 0; i < 64; i = i + 1) begin
            i_buf1 = i;
            subtraction_lut[i_buf1] = i_buf1 - 1'b1;
        end
        
        for (i = 64; i < 128; i = i + 1) begin
            i_buf2 = i;
            subtraction_lut[i_buf2] = i_buf2 - 1'b1;
        end
        
        for (i = 128; i < 192; i = i + 1) begin
            i_buf3 = i;
            subtraction_lut[i_buf3] = i_buf3 - 1'b1;
        end
        
        for (i = 192; i < 256; i = i + 1) begin
            i_buf4 = i;
            subtraction_lut[i_buf4] = i_buf4 - 1'b1;
        end
    end
    
    // 创建q_out的缓冲寄存器，用于减少查找表访问的扇出负载
    reg [WIDTH-1:0] q_out_buf;
    
    // 查找表访问逻辑
    always @(posedge clk) begin
        q_out_buf <= q_out;
    end
    
    // 减法计算使用查找表
    always @(posedge clk) begin
        if (rst)
            q_out <= {WIDTH{1'b1}};  // Reset to all 1's
        else if (enable)
            q_out <= subtraction_lut[q_out_buf];  // 使用查找表实现减法，通过缓冲减少扇出负载
    end
endmodule