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

// FIFO存储器
reg [FIFO_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

// 写指针和读指针
reg [7:0] wr_ptr_stage1, wr_ptr_stage2;
reg [7:0] rd_ptr_stage1, rd_ptr_stage2;

// 写入数据拼接流水线
reg [FIFO_WIDTH-1:0] fifo_data_stage1, fifo_data_stage2;

// 同步读指针
wire [7:0] rd_ptr_sync;

// 写入控制流水线
always @(posedge clk) begin
    if (fifo_flush) begin
        wr_ptr_stage1 <= 8'd0;
        wr_ptr_stage2 <= 8'd0;
        fifo_data_stage1 <= {FIFO_WIDTH{1'b0}};
        fifo_data_stage2 <= {FIFO_WIDTH{1'b0}};
    end else begin
        // stage 1: 拼接数据
        if (rx_valid && !fifo_full) begin
            fifo_data_stage1 <= {frame_err, parity_err, rx_data};
            wr_ptr_stage1 <= wr_ptr_stage2;
        end
        // stage 2: 写入FIFO
        if (rx_valid && !fifo_full) begin
            fifo_data_stage2 <= fifo_data_stage1;
            fifo_mem[wr_ptr_stage1] <= fifo_data_stage2;
            wr_ptr_stage2 <= wr_ptr_stage1 + 1'b1;
        end
    end
end

// 读指针流水线控制
always @(posedge rx_clk) begin
    if (fifo_flush) begin
        rd_ptr_stage1 <= 8'd0;
        rd_ptr_stage2 <= 8'd0;
    end else if (!fifo_empty) begin
        rd_ptr_stage1 <= rd_ptr_stage2;
        rd_ptr_stage2 <= rd_ptr_stage1 + 1'b1;
    end
end

// 读指针跨时钟域同步流水线（3级同步器）
reg [7:0] rd_ptr_sync_reg1_stage1, rd_ptr_sync_reg1_stage2, rd_ptr_sync_reg1_stage3;

always @(posedge clk) begin
    rd_ptr_sync_reg1_stage1 <= rd_ptr_stage2;
    rd_ptr_sync_reg1_stage2 <= rd_ptr_sync_reg1_stage1;
    rd_ptr_sync_reg1_stage3 <= rd_ptr_sync_reg1_stage2;
end

assign rd_ptr_sync = rd_ptr_sync_reg1_stage3;

// FIFO状态计算流水线
reg [7:0] wr_ptr_sync_stage1, wr_ptr_sync_stage2;
reg [7:0] rd_ptr_sync_stage1, rd_ptr_sync_stage2;
reg fifo_full_stage1, fifo_full_stage2;
reg fifo_empty_stage1, fifo_empty_stage2;

// 优化后的比较逻辑
// 使用范围比较代替逐项比较链，提高综合效率
always @(posedge clk) begin
    wr_ptr_sync_stage1 <= wr_ptr_stage2;
    wr_ptr_sync_stage2 <= wr_ptr_sync_stage1;
    rd_ptr_sync_stage1 <= rd_ptr_sync;
    rd_ptr_sync_stage2 <= rd_ptr_sync_stage1;

    // 优化后的满判断: 判断指针差是否在FIFO_DEPTH范围内
    fifo_full_stage1 <= ((wr_ptr_sync_stage1 - rd_ptr_sync_stage1) >= FIFO_DEPTH[7:0]);
    fifo_full_stage2 <= fifo_full_stage1;

    // 优化后的空判断: 指针相等即为空
    fifo_empty_stage1 <= (wr_ptr_sync_stage1 == rd_ptr_sync_stage1);
    fifo_empty_stage2 <= fifo_empty_stage1;
end

assign fifo_full  = fifo_full_stage2;
assign fifo_empty = fifo_empty_stage2;

endmodule