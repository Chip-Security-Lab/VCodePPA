//SystemVerilog
module dynamic_ring_buf #(parameter MAX_DEPTH=16, DW=8) (
    input clk, rst_n,
    input [3:0] depth_set,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output full, empty
);
    reg [DW-1:0] mem[MAX_DEPTH-1:0];
    reg [3:0] wr_ptr, rd_ptr, cnt;
    reg [3:0] depth;
    
    // 为高扇出信号添加缓冲寄存器
    reg [3:0] depth_buf1, depth_buf2;
    reg [3:0] cnt_buf1, cnt_buf2;
    reg [DW-1:0] mem_rd_data;
    wire b0;
    reg b0_buf1, b0_buf2;
    
    // 深度设置缓冲 - 减少depth_set的扇出负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            depth <= 4'b0;
            depth_buf1 <= 4'b0;
            depth_buf2 <= 4'b0;
        end
        else begin
            // 缓冲处理depth_set并限制范围
            depth_buf1 <= (depth_set > 0 && depth_set < MAX_DEPTH) ? depth_set : MAX_DEPTH;
            depth_buf2 <= depth_buf1;
            depth <= depth_buf2;
        end
    end
    
    // 使用缓冲的cnt减少扇出负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_buf1 <= 4'b0;
            cnt_buf2 <= 4'b0;
        end
        else begin
            cnt_buf1 <= cnt;
            cnt_buf2 <= cnt_buf1;
        end
    end
    
    // 使用缓冲后的信号计算状态标志
    assign b0 = (cnt_buf2 == 4'b0);
    assign empty = b0;
    assign full = (cnt_buf2 >= depth);
    
    // 缓冲b0信号减少扇出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b0_buf1 <= 1'b1;
            b0_buf2 <= 1'b1;
        end
        else begin
            b0_buf1 <= b0;
            b0_buf2 <= b0_buf1;
        end
    end
    
    // 计算下一个指针位置，使用缓冲的depth以减少扇出
    wire [3:0] next_wr_ptr = (wr_ptr == depth - 1) ? 4'b0 : wr_ptr + 4'b1;
    wire [3:0] next_rd_ptr = (rd_ptr == depth - 1) ? 4'b0 : rd_ptr + 4'b1;
    
    // 预读取内存以降低关键路径延迟
    always @(posedge clk) begin
        mem_rd_data <= mem[rd_ptr];
    end
    
    // 主要控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 4'b0;
            rd_ptr <= 4'b0;
            cnt <= 4'b0;
            dout <= {DW{1'b0}};
        end
        else begin
            case({wr_en & ~full, rd_en & ~empty})
                2'b10: begin // 只写
                    mem[wr_ptr] <= din;
                    wr_ptr <= next_wr_ptr;
                    cnt <= cnt + 4'b1;
                end
                2'b01: begin // 只读
                    dout <= mem_rd_data;
                    rd_ptr <= next_rd_ptr;
                    cnt <= cnt - 4'b1;
                end
                2'b11: begin // 同时读写
                    mem[wr_ptr] <= din;
                    wr_ptr <= next_wr_ptr;
                    dout <= mem_rd_data;
                    rd_ptr <= next_rd_ptr;
                    // 读写同时发生时，计数器保持不变
                end
                default: begin // 无操作
                    // 保持当前状态
                end
            endcase
        end
    end
endmodule