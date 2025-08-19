//SystemVerilog
module async_low_rst_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4,
    // 使用宽度参数自动计算地址宽度
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    wr_en,
    input  wire                    rd_en,
    input  wire [DATA_WIDTH-1:0]   din,
    output reg  [DATA_WIDTH-1:0]   dout,
    output wire                    empty,
    output wire                    full
);

    // 使用参数化的地址宽度
    reg [DATA_WIDTH-1:0] fifo_mem[0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0]   fifo_count; // 额外1位用于判断满状态

    // 简化的空和满状态逻辑判断
    assign empty = (fifo_count == 0);
    assign full  = (fifo_count == DEPTH);

    // 优化读写使能信号，避免无效操作
    wire valid_write = wr_en && !full;
    wire valid_read  = rd_en && !empty;

    // 写指针逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (valid_write) begin
            wr_ptr <= (wr_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : wr_ptr + 1'b1;
        end
    end

    // 读指针逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (valid_read) begin
            rd_ptr <= (rd_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : rd_ptr + 1'b1;
        end
    end

    // FIFO计数器逻辑，优化比较链
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_count <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            case ({valid_write, valid_read})
                2'b10: fifo_count <= fifo_count + 1'b1; // 只写
                2'b01: fifo_count <= fifo_count - 1'b1; // 只读
                default: fifo_count <= fifo_count;      // 同时读写或无操作
            endcase
        end
    end

    // 写存储器操作
    always @(posedge clk) begin
        if (valid_write) begin
            fifo_mem[wr_ptr] <= din;
        end
    end

    // 读操作，与存储器写操作分离
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {DATA_WIDTH{1'b0}};
        end else if (valid_read) begin
            dout <= fifo_mem[rd_ptr];
        end
    end

endmodule