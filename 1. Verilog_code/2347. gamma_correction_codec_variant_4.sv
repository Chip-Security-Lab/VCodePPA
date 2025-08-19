//SystemVerilog
module gamma_correction_codec (
    input wire clk,
    input wire enable, 
    input wire reset,
    input wire [7:0] pixel_in,
    input wire [2:0] gamma_factor,
    output reg [7:0] pixel_out
);
    // 优化LUT存储结构，使用单一维度减少索引复杂度
    reg [15:0] gamma_lut [0:2047]; // 8*256 = 2048 项
    integer index, i;
    
    // 初始化查找表 - 使用单一索引计算提高效率
    initial begin
        for (i = 0; i < 2048; i = i + 1) begin
            index = i % 256;        // 像素值
            gamma_lut[i] = index * (1 + (i / 256)); // gamma因子计算
        end
    end
    
    // 后向寄存器重定时：将靠近输出的寄存器移到组合逻辑之前
    reg [10:0] lut_addr_reg;
    
    // 寄存先存储地址
    always @(posedge clk) begin
        if (reset)
            lut_addr_reg <= 11'h000;
        else if (enable)
            lut_addr_reg <= {gamma_factor, pixel_in};
    end
    
    // 使用寄存后的地址访问LUT
    wire [15:0] gamma_result = gamma_lut[lut_addr_reg];
    
    // 输出逻辑
    always @(posedge clk) begin
        if (reset)
            pixel_out <= 8'h00;
        else if (enable)
            pixel_out <= gamma_result[7:0];
    end
endmodule