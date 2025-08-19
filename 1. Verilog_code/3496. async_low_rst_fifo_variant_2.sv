//SystemVerilog
module async_low_rst_fifo #(parameter DATA_WIDTH=8, DEPTH=4)(
    input wire clk,
    input wire rst_n,
    input wire wr_en, rd_en,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output wire empty, full
);
    // 寄存器和存储器声明
    reg [DATA_WIDTH-1:0] fifo_mem[0:DEPTH-1];
    reg [1:0] wr_ptr, rd_ptr;
    reg [2:0] fifo_count;
    
    // 寄存输入信号以实现前向寄存器重定时
    reg wr_en_reg, rd_en_reg;
    reg [DATA_WIDTH-1:0] din_reg;
    
    // 预先计算组合逻辑，减少关键路径延迟
    wire will_write, will_read;
    wire [2:0] next_fifo_count;
    wire [1:0] next_wr_ptr, next_rd_ptr;
    
    // 状态计算逻辑
    assign empty = (fifo_count == 0);
    assign full = (fifo_count == DEPTH);
    
    assign will_write = wr_en_reg && !full;
    assign will_read = rd_en_reg && !empty;
    
    assign next_wr_ptr = will_write ? wr_ptr + 1'b1 : wr_ptr;
    assign next_rd_ptr = will_read ? rd_ptr + 1'b1 : rd_ptr;
    
    assign next_fifo_count = (will_write && !will_read) ? fifo_count + 1'b1 :
                            (!will_write && will_read) ? fifo_count - 1'b1 :
                            fifo_count;
    
    // 输入信号寄存处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_reg <= 1'b0;
            rd_en_reg <= 1'b0;
            din_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            wr_en_reg <= wr_en;
            rd_en_reg <= rd_en;
            din_reg <= din;
        end
    end
    
    // 主状态更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 2'b0;
            rd_ptr <= 2'b0;
            fifo_count <= 3'b0;
            dout <= {DATA_WIDTH{1'b0}};
        end else begin
            wr_ptr <= next_wr_ptr;
            rd_ptr <= next_rd_ptr;
            fifo_count <= next_fifo_count;
            
            if (will_read) begin
                dout <= fifo_mem[rd_ptr];
            end
            
            if (will_write) begin
                fifo_mem[wr_ptr] <= din_reg;
            end
        end
    end
endmodule