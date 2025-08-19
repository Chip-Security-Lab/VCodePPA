//SystemVerilog
module video_timing #(
    parameter H_TOTAL = 800
)(
    input wire clk,
    output reg h_sync,
    output wire [9:0] h_count
);
    reg [9:0] cnt;
    reg cnt_max;
    
    // 缓冲寄存器，用于分散cnt的扇出负载
    reg [9:0] cnt_buf1, cnt_buf2;
    
    // 提前计算终止条件，减少关键路径判断逻辑
    always @(*) begin
        cnt_max = (cnt == H_TOTAL-1);
    end
    
    // 分离计数器逻辑
    always @(posedge clk) begin
        cnt <= cnt_max ? 10'd0 : cnt + 10'd1;
    end
    
    // 缓冲寄存器用于分散cnt的扇出负载
    always @(posedge clk) begin
        cnt_buf1 <= cnt;
        cnt_buf2 <= cnt;
    end
    
    // 使用缓冲寄存器处理h_sync判断，减少逻辑深度
    always @(posedge clk) begin
        h_sync <= ~(cnt_buf1 < 96);
    end
    
    // 使用另一个缓冲寄存器连接到输出，平衡负载
    assign h_count = cnt_buf2;
    
endmodule