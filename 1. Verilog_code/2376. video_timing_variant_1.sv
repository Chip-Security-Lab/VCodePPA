//SystemVerilog
//IEEE 1364-2005
module video_timing #(parameter H_TOTAL=800)(
    input      clk,
    output reg h_sync,
    output     [9:0] h_count
);
    reg [9:0] cnt;
    
    // 分离的缓冲寄存器，用于不同的信号路径
    reg [9:0] cnt_h_count_buf;    // 专用于h_count输出
    reg [9:0] cnt_h_sync_buf;     // 专用于h_sync逻辑
    
    // 额外的缓冲寄存器，用于平衡负载
    reg [9:0] cnt_buf_a;
    reg [9:0] cnt_buf_b;
    
    // 主计数器逻辑
    always @(posedge clk) begin
        cnt <= (cnt < H_TOTAL-1) ? cnt + 1 : 10'd0;
    end
    
    // 第一级缓冲 - 分散cnt的扇出负载
    always @(posedge clk) begin
        cnt_buf_a <= cnt;
        cnt_buf_b <= cnt;
    end
    
    // 第二级缓冲 - 进一步分散扇出负载并连接到各个功能块
    always @(posedge clk) begin
        cnt_h_count_buf <= cnt_buf_a;
        cnt_h_sync_buf  <= cnt_buf_b;
    end
    
    // h_sync生成逻辑 - 使用专用缓冲
    always @(posedge clk) begin
        h_sync <= (cnt_h_sync_buf < 10'd96) ? 1'b0 : 1'b1;
    end
    
    // 使用专用缓冲输出h_count
    assign h_count = cnt_h_count_buf;
    
endmodule