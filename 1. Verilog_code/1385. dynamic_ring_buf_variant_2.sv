//SystemVerilog
module dynamic_ring_buf #(parameter MAX_DEPTH=16, DW=8) (
    input clk, rst_n,
    input [3:0] depth_set,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output full, empty
);
    // 存储器分组以优化访问
    reg [DW-1:0] mem_rd_bank[MAX_DEPTH-1:0];
    reg [DW-1:0] mem_wr_bank[MAX_DEPTH-1:0];
    
    // 为高扇出信号添加寄存器缓冲
    reg [3:0] depth_buf1, depth_buf2;
    reg [3:0] wr_ptr=0, rd_ptr=0;
    reg [3:0] cnt=0, cnt_buf1, cnt_buf2;
    
    // 深度计算逻辑
    wire [3:0] depth_comb = (depth_set < MAX_DEPTH) ? depth_set : MAX_DEPTH;
    
    // 预先读取下一个数据，移动寄存器到组合逻辑前
    reg [DW-1:0] next_data;
    reg rd_valid;
    
    // 内存写入和读取使用单独的路径和缓冲
    // 将深度信号缓存到多个寄存器以减少扇出
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            depth_buf1 <= 0;
            depth_buf2 <= 0;
        end
        else begin
            depth_buf1 <= depth_comb;
            depth_buf2 <= depth_comb;
        end
    end
    
    // 计数器缓冲寄存器以减少扇出
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt_buf1 <= 0;
            cnt_buf2 <= 0;
        end
        else begin
            cnt_buf1 <= cnt;
            cnt_buf2 <= cnt;
        end
    end
    
    // 主状态更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
            rd_valid <= 0;
            next_data <= 0;
        end
        else begin
            case({wr_en, rd_en})
                2'b10: if(cnt < depth_buf1) begin
                    mem_wr_bank[wr_ptr] <= din;
                    wr_ptr <= (wr_ptr + 1) % depth_buf1;
                    cnt <= cnt + 1;
                    rd_valid <= 0;
                end
                2'b01: if(cnt > 0) begin
                    // 寄存器重定时：提前读取数据
                    next_data <= mem_rd_bank[rd_ptr];
                    rd_ptr <= (rd_ptr + 1) % depth_buf1;
                    cnt <= cnt - 1;
                    rd_valid <= 1;
                end
                2'b11: begin
                    mem_wr_bank[wr_ptr] <= din;
                    wr_ptr <= (wr_ptr + 1) % depth_buf2;
                    // 寄存器重定时：提前读取数据
                    next_data <= mem_rd_bank[rd_ptr];
                    rd_ptr <= (rd_ptr + 1) % depth_buf2;
                    rd_valid <= 1;
                end
                default: begin
                    rd_valid <= 0;
                end
            endcase
        end
    end
    
    // 内存同步机制 - 确保读写一致性
    integer i;
    always @(posedge clk) begin
        for (i = 0; i < MAX_DEPTH; i = i + 1) begin
            mem_rd_bank[i] <= mem_wr_bank[i];
        end
    end
    
    // 输出寄存器移至组合逻辑前
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= 0;
        end
        else if(rd_valid) begin
            dout <= next_data;
        end
    end
    
    // 使用缓冲的计数器信号来生成状态输出
    assign full = (cnt_buf1 == depth_buf2);
    assign empty = (cnt_buf2 == 0);
endmodule