//SystemVerilog - IEEE 1364-2005
module parallel_codec #(
    parameter DW=16, AW=4, DEPTH=8
)(
    input wire clk, valid, ready,
    input wire [DW-1:0] din,
    output reg [DW-1:0] dout,
    output wire ack
);
    reg [DW-1:0] buffer [0:DEPTH-1];
    reg [AW-1:0] wr_ptr, rd_ptr;
    reg [AW-1:0] wr_ptr_next;
    reg valid_ready_reg;
    reg [DW-1:0] din_reg;
    
    // 缓冲区状态信号
    wire empty;
    reg [AW:0] count; // 增加1位以防溢出
    
    // 高扇出信号缓冲
    reg [AW-1:0] wr_ptr_buf1, wr_ptr_buf2;
    reg [AW-1:0] rd_ptr_buf1, rd_ptr_buf2;
    reg empty_buf1, empty_buf2;
    reg [AW:0] count_buf1, count_buf2;
    
    // 使用计数器优化比较逻辑
    assign empty = (count == 0);
    assign ack = !empty_buf2; // 使用缓冲后的empty信号
    
    // 将组合逻辑和写操作分开到不同阶段
    always @(posedge clk) begin
        // 第一级流水线：寄存输入信号和计算下一个写指针位置
        valid_ready_reg <= valid && ready;
        din_reg <= din;
        wr_ptr_next <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1'b1;
        
        // 高扇出信号缓冲更新
        wr_ptr_buf1 <= wr_ptr;
        wr_ptr_buf2 <= wr_ptr_buf1;
        
        rd_ptr_buf1 <= rd_ptr;
        rd_ptr_buf2 <= rd_ptr_buf1;
        
        empty_buf1 <= empty;
        empty_buf2 <= empty_buf1;
        
        count_buf1 <= count;
        count_buf2 <= count_buf1;
        
        // 第二级流水线：执行实际的内存写入和指针更新
        if(valid_ready_reg) begin
            buffer[wr_ptr] <= din_reg;
            wr_ptr <= wr_ptr_next;
            
            // 更新计数器逻辑
            if (count < DEPTH)
                count <= count + 1'b1;
        end
        
        // 读取逻辑
        if (!empty && ready) begin
            dout <= buffer[rd_ptr];
            rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1'b1;
            count <= count - 1'b1;
        end
    end
    
    // 初始化块
    initial begin
        wr_ptr = 0;
        rd_ptr = 0;
        count = 0;
        wr_ptr_buf1 = 0;
        wr_ptr_buf2 = 0;
        rd_ptr_buf1 = 0;
        rd_ptr_buf2 = 0;
        empty_buf1 = 1'b1;
        empty_buf2 = 1'b1;
        count_buf1 = 0;
        count_buf2 = 0;
    end
endmodule