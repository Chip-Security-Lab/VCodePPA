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
reg [7:0] write_pointer, read_pointer;
wire [7:0] read_pointer_sync;

// 写入控制逻辑
always @(posedge clk) begin
    if (fifo_flush) begin
        write_pointer <= 8'd0;
    end else if (rx_valid && ~fifo_full) begin
        fifo_mem[write_pointer] <= {frame_err, parity_err, rx_data};
        write_pointer <= write_pointer + 8'd1;
    end
end

// 读取控制逻辑
always @(posedge rx_clk) begin
    if (fifo_flush) begin
        read_pointer <= 8'd0;
    end else if (~fifo_empty) begin
        read_pointer <= read_pointer + 8'd1;
    end
end

// 跨时钟域同步器
reg [7:0] read_pointer_sync_reg1;
reg [7:0] read_pointer_sync_reg2;

always @(posedge clk) begin
    read_pointer_sync_reg1 <= read_pointer;
    read_pointer_sync_reg2 <= read_pointer_sync_reg1;
end

assign read_pointer_sync = read_pointer_sync_reg2;

// 优化先行借位减法器用于fifo_count
wire [7:0] fifo_count;
wire [7:0] borrow_gen;
wire [7:0] borrow_prop;
wire [8:0] borrow_chain;
genvar idx;

assign borrow_chain[0] = 1'b0;
generate
    for (idx = 0; idx < 8; idx = idx + 1) begin : gen_borrow_lookahead
        // 原表达式：
        // assign diff_generate[i]  = (~write_pointer[i]) & read_pointer_sync[i];
        // assign diff_propagate[i] = ~(write_pointer[i] ^ read_pointer_sync[i]);
        // assign borrow_chain[i+1] = diff_generate[i] | (diff_propagate[i] & borrow_chain[i]);
        // assign fifo_count[i]     = write_pointer[i] ^ read_pointer_sync[i] ^ borrow_chain[i];
        //
        // 优化后表达式（应用布尔代数简化）：
        // diff_generate = ~A & B = B & ~A
        // diff_propagate = ~(A ^ B) = A ~^ B
        // borrow_chain[i+1] = (B & ~A) | ((A ~^ B) & borrow_chain[i])
        // fifo_count[i] = A ^ B ^ borrow_chain[i]
        assign borrow_gen[idx]  = read_pointer_sync[idx] & ~write_pointer[idx];
        assign borrow_prop[idx] = ~(write_pointer[idx] ^ read_pointer_sync[idx]);
        assign borrow_chain[idx+1] = borrow_gen[idx] | (borrow_prop[idx] & borrow_chain[idx]);
        assign fifo_count[idx]     = write_pointer[idx] ^ read_pointer_sync[idx] ^ borrow_chain[idx];
    end
endgenerate

// 优化后的满/空标志逻辑
assign fifo_full  = (fifo_count >= FIFO_DEPTH[7:0]);
assign fifo_empty = (write_pointer == read_pointer);

endmodule