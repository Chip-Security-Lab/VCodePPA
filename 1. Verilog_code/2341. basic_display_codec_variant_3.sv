//SystemVerilog
//IEEE 1364-2005 Verilog
module basic_display_codec (
    input clk, rst_n,
    input [7:0] pixel_in,
    output reg [15:0] display_out
);
    // 中间信号，用于存储重新定时的像素数据
    reg [7:0] pixel_registered;
    
    // 注册输入像素数据
    always @(posedge clk)
        pixel_registered <= (!rst_n) ? 8'h00 : pixel_in;
    
    // 将组合逻辑移到寄存器之后
    always @(posedge clk)
        display_out <= (!rst_n) ? 16'h0000 : 
                      {pixel_registered[7:5], 5'b0, 
                       pixel_registered[4:2], 5'b0, 
                       pixel_registered[1:0], 6'b0};
endmodule