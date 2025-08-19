//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module dual_clock_codec #(
    parameter DATA_WIDTH = 24,
    parameter FIFO_DEPTH = 4
) (
    input src_clk, dst_clk, rst,
    input [DATA_WIDTH-1:0] data_in,
    input wr_en, rd_en,
    output reg [15:0] data_out,
    output full, empty
);
    // Memory array
    reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
    
    // Pointer registers with dedicated buffer registers
    reg [$clog2(FIFO_DEPTH):0] wr_ptr, wr_ptr_buf1, wr_ptr_buf2;
    reg [$clog2(FIFO_DEPTH):0] rd_ptr, rd_ptr_buf1, rd_ptr_buf2;
    
    // FIFO address extraction with dedicated buffers
    wire [$clog2(FIFO_DEPTH)-1:0] wr_addr;
    wire [$clog2(FIFO_DEPTH)-1:0] rd_addr;
    reg [$clog2(FIFO_DEPTH)-1:0] wr_addr_buf, rd_addr_buf;
    
    // MSB extraction with dedicated buffers
    wire wr_msb, rd_msb;
    reg wr_msb_buf, rd_msb_buf;
    
    // 写逻辑状态定义
    localparam WR_IDLE = 2'b00;
    localparam WR_ACTIVE = 2'b01;
    reg [1:0] wr_state;
    
    // Data buffer registers
    reg [DATA_WIDTH-1:0] data_in_buf;
    
    // 高扇出信号缓冲 - clog2表达式缓冲
    wire [$clog2(FIFO_DEPTH)-1:0] clog2_mask;
    assign clog2_mask = {$clog2(FIFO_DEPTH){1'b1}};
    
    // 写逻辑 (输入时钟域)
    always @(posedge src_clk) begin
        // 缓冲输入数据
        data_in_buf <= data_in;
        
        case ({rst, wr_en && !full})
            2'b10, 2'b11: begin  // 复位优先
                wr_ptr <= 0;
                wr_state <= WR_IDLE;
            end
            2'b01: begin  // 写使能且非满
                fifo[wr_ptr_buf1[$clog2(FIFO_DEPTH)-1:0]] <= data_in_buf;
                wr_ptr <= wr_ptr + 1;
                wr_state <= WR_ACTIVE;
            end
            2'b00: begin  // 无操作
                wr_state <= WR_IDLE;
            end
        endcase
        
        // 更新wr_ptr缓冲寄存器用于扇出减少
        wr_ptr_buf1 <= wr_ptr;
        wr_ptr_buf2 <= wr_ptr_buf1;
    end
    
    // 读逻辑状态定义
    localparam RD_IDLE = 2'b00;
    localparam RD_ACTIVE = 2'b01;
    reg [1:0] rd_state;
    
    // 缓冲FIFO读取数据
    reg [DATA_WIDTH-1:0] fifo_read_data, fifo_read_data_buf;
    
    // 读逻辑 (输出时钟域) 带RGB转换
    always @(posedge dst_clk) begin
        case ({rst, rd_en && !empty})
            2'b10, 2'b11: begin  // 复位优先
                rd_ptr <= 0;
                data_out <= 0;
                rd_state <= RD_IDLE;
            end
            2'b01: begin  // 读使能且非空
                // 使用缓冲的数据进行处理
                fifo_read_data <= fifo[rd_ptr_buf1[$clog2(FIFO_DEPTH)-1:0]];
                rd_ptr <= rd_ptr + 1;
                rd_state <= RD_ACTIVE;
            end
            2'b00: begin  // 无操作
                rd_state <= RD_IDLE;
            end
        endcase
        
        // 缓冲数据转换
        fifo_read_data_buf <= fifo_read_data;
        
        // 使用缓冲的数据产生输出
        data_out <= {fifo_read_data_buf[23:19], 
                     fifo_read_data_buf[15:10],
                     fifo_read_data_buf[7:3]};
        
        // 更新rd_ptr缓冲寄存器用于扇出减少
        rd_ptr_buf1 <= rd_ptr;
        rd_ptr_buf2 <= rd_ptr_buf1;
    end
    
    // FIFO状态逻辑 - 使用缓冲寄存器减少扇出
    assign wr_addr = wr_ptr[$clog2(FIFO_DEPTH)-1:0];
    assign rd_addr = rd_ptr[$clog2(FIFO_DEPTH)-1:0];
    assign wr_msb = wr_ptr[$clog2(FIFO_DEPTH)];
    assign rd_msb = rd_ptr[$clog2(FIFO_DEPTH)];
    
    // 缓冲地址和MSB减少扇出
    always @(posedge src_clk) begin
        wr_addr_buf <= wr_addr;
        wr_msb_buf <= wr_msb;
    end
    
    always @(posedge dst_clk) begin
        rd_addr_buf <= rd_addr;
        rd_msb_buf <= rd_msb;
    end
    
    // 使用缓冲的MSB和地址计算FIFO状态
    assign full = (wr_addr_buf == rd_addr_buf) && (wr_msb_buf != rd_msb_buf);
    assign empty = (wr_ptr_buf2 == rd_ptr_buf2);
endmodule