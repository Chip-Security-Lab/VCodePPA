//SystemVerilog
module UART_SyncFIFO #(
    parameter FIFO_DEPTH = 64,
    parameter FIFO_WIDTH = 10  // 8数据+1奇偶+1状态
)(
    input  wire             clk,       
    input  wire             rx_clk,    
    input  wire             rx_valid,  
    input  wire [7:0]       rx_data,   
    input  wire             frame_err, 
    input  wire             parity_err,
    output wire             fifo_full,
    output wire             fifo_empty,
    input  wire             fifo_flush 
);
// 精确水位指示
localparam FIFO_THRESH = FIFO_DEPTH - 4;
reg [FIFO_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
reg [7:0] wr_ptr_reg, rd_ptr_reg;
wire [7:0] rd_ptr_sync;
reg [FIFO_WIDTH-1:0] fifo_data_reg;
reg fifo_full_reg, fifo_empty_reg;

// 写入控制逻辑
always @(posedge clk) begin
    if (fifo_flush) begin
        wr_ptr_reg <= 8'd0;
    end else if (rx_valid && !fifo_full_reg) begin
        fifo_mem[wr_ptr_reg] <= {frame_err, parity_err, rx_data};
        wr_ptr_reg <= wr_ptr_reg + 8'd1;
    end
end

// 读取控制逻辑
always @(posedge rx_clk) begin
    if (fifo_flush) begin
        rd_ptr_reg <= 8'd0;
    end else if (!fifo_empty_reg) begin
        rd_ptr_reg <= rd_ptr_reg + 8'd1;
    end
end

// 跨时钟域同步器
reg [7:0] rd_ptr_sync_stage1;
reg [7:0] rd_ptr_sync_stage2;

always @(posedge clk) begin
    rd_ptr_sync_stage1 <= rd_ptr_reg;
    rd_ptr_sync_stage2 <= rd_ptr_sync_stage1;
end

assign rd_ptr_sync = rd_ptr_sync_stage2;

// 优化的FIFO状态计算
always @(posedge clk) begin
    if (fifo_flush) begin
        fifo_full_reg  <= 1'b0;
        fifo_empty_reg <= 1'b1;
    end else begin
        // 优化比较链：利用范围比较和避免不必要的算术
        // wr_ptr_reg - rd_ptr_sync == 0 --> empty
        // wr_ptr_reg - rd_ptr_sync >= FIFO_DEPTH --> full
        // 由于FIFO_DEPTH为2的幂次，wr_ptr_reg和rd_ptr_sync均为8位，可直接用减法比较高位
        // 使用无符号比较优化
        fifo_empty_reg <= (wr_ptr_reg == rd_ptr_reg);

        // 优化：直接比较高位差值是否大于等于FIFO_DEPTH
        // 先计算有效计数
        // 由于FIFO_DEPTH <= 256, wr_ptr_reg和rd_ptr_sync都是8位
        // count = wr_ptr_reg - rd_ptr_sync;
        // full if count[7:0] >= FIFO_DEPTH
        fifo_full_reg <= (({1'b0, wr_ptr_reg} - {1'b0, rd_ptr_sync}) >= FIFO_DEPTH);
    end
end

assign fifo_full  = fifo_full_reg;
assign fifo_empty = fifo_empty_reg;

endmodule