//SystemVerilog
module MorphFilter #(parameter W=8) (
    input clk,
    input [W-1:0] pixel_in,
    output reg [W-1:0] pixel_out
);
    reg [W-1:0] window [0:8];
    reg [W-1:0] window_buf3, window_buf4, window_buf5;
    integer i;
    
    always @(posedge clk) begin
        // 手动移位窗口
        for(i=8; i>0; i=i-1)
            window[i] <= window[i-1];
        window[0] <= pixel_in;
        
        // 为高扇出信号添加缓冲寄存器
        window_buf3 <= window[3];
        window_buf4 <= window[4];
        window_buf5 <= window[5];
        
        // 使用缓冲后的信号进行垂直膨胀操作
        pixel_out <= (window_buf3 | window_buf4 | window_buf5) ? 8'hFF : 8'h00;
    end
endmodule