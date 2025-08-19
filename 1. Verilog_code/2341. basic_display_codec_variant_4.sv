//SystemVerilog
module basic_display_codec (
    input wire clk, rst_n,
    input wire [7:0] pixel_in,
    output reg [15:0] display_out
);
    // 预先计算RGB映射以减少逻辑延迟路径
    wire [4:0] red_mapped;
    wire [4:0] green_mapped;
    wire [5:0] blue_mapped;
    
    // 将8位像素映射为16位RGB565格式
    assign red_mapped = {pixel_in[7:5], 2'b00};
    assign green_mapped = {pixel_in[4:2], 2'b00};
    assign blue_mapped = {pixel_in[1:0], 4'b0000};
    
    // 使用条件运算符替代if-else结构
    always @(posedge clk or negedge rst_n)
        display_out <= (!rst_n) ? 16'h0000 : {red_mapped, green_mapped, blue_mapped};
endmodule