module async_fifo #(parameter DW=16, DEPTH=8) (
    input wr_clk, rd_clk, rst,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,  // 修改为output reg
    output full, empty
);
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [2:0] wr_ptr, rd_ptr;
    reg [2:0] wr_ptr_gray, rd_ptr_gray;
    reg [2:0] rd_ptr_sync, wr_ptr_sync;  // 添加同步寄存器
    
    // 写域
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
        end
    end
    
    // 读域
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            dout <= 0;
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
        end
    end
    
    // 同步格雷码
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            rd_ptr_sync <= 0;
        else
            rd_ptr_sync <= rd_ptr_gray;
    end
    
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            wr_ptr_sync <= 0;
        else
            wr_ptr_sync <= wr_ptr_gray;
    end
    
    // 生成满和空标志
    assign full = (wr_ptr_gray == {~rd_ptr_sync[2], rd_ptr_sync[1:0]});
    assign empty = (rd_ptr_gray == wr_ptr_sync);
endmodule