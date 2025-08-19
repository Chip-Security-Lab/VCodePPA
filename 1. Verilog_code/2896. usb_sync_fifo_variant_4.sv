//SystemVerilog
module usb_sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  wire                   clk,
    input  wire                   rst_b,
    input  wire                   write_en,
    input  wire                   read_en,
    input  wire [DATA_WIDTH-1:0]  data_in,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire                   full,
    output wire                   empty
);
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0]   count;
    
    // 寄存输入信号，将寄存器向前移动
    reg                  write_en_r;
    reg                  read_en_r;
    reg [DATA_WIDTH-1:0] data_in_r;
    
    // 缓存读出的数据
    reg [DATA_WIDTH-1:0] data_out_r;
    
    // 输出分配
    assign data_out = data_out_r;
    
    // 优化的比较逻辑
    assign empty = (count == {(ADDR_WIDTH+1){1'b0}});
    assign full  = (count[ADDR_WIDTH-1:0] == {ADDR_WIDTH{1'b0}}) && count[ADDR_WIDTH];
    
    // 输入信号寄存器化
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            write_en_r <= 1'b0;
            read_en_r  <= 1'b0;
            data_in_r  <= {DATA_WIDTH{1'b0}};
        end else begin
            write_en_r <= write_en;
            read_en_r  <= read_en;
            data_in_r  <= data_in;
        end
    end
    
    // 创建写入和读取操作的控制信号
    wire write_operation = write_en_r && !full;
    wire read_operation = read_en_r && !empty;
    
    // 指针和计数器逻辑
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            count <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            // 优化计数器逻辑
            case ({write_operation, read_operation})
                2'b10: count <= count + 1'b1; // 只写
                2'b01: count <= count - 1'b1; // 只读
                // 2'b11和2'b00情况下count保持不变
            endcase
            
            // 写指针逻辑
            if (write_operation) begin
                mem[wr_ptr] <= data_in_r;
                wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? {ADDR_WIDTH{1'b0}} : wr_ptr + 1'b1;
            end
            
            // 读指针逻辑
            if (read_operation) begin
                rd_ptr <= (rd_ptr == FIFO_DEPTH-1) ? {ADDR_WIDTH{1'b0}} : rd_ptr + 1'b1;
            end
        end
    end
    
    // 分离读取数据路径，提高时序性能
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            data_out_r <= {DATA_WIDTH{1'b0}};
        end else if (read_operation) begin
            data_out_r <= mem[rd_ptr];
        end
    end
endmodule