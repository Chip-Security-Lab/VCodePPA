//SystemVerilog
module johnson_counter (
    input wire clk, rst,
    output reg [3:0] q
);
    // 内部缓冲寄存器，用于减少q的扇出负载
    reg [3:0] q_buf1, q_buf2;
    reg [2:0] q_internal;
    wire next_bit;
    
    // 使用缓冲后的q信号计算next_bit，减少关键路径延迟
    assign next_bit = ~q_buf1[3];
    
    always @(posedge clk) begin
        if (rst) begin
            q_internal <= 3'b000;
            q[3] <= 1'b0;
            q_buf1 <= 4'b0000;
            q_buf2 <= 4'b0000;
        end else begin
            // 前向重定时：将位移操作提前处理
            q_internal <= q_buf1[2:0];
            q[3] <= next_bit;
            // 更新缓冲寄存器
            q_buf1 <= q;
            q_buf2 <= q_buf1;
        end
    end
    
    // 连接内部状态到输出的低3位
    always @(posedge clk) begin
        if (rst)
            q[2:0] <= 3'b000;
        else
            q[2:0] <= q_internal;
    end
endmodule