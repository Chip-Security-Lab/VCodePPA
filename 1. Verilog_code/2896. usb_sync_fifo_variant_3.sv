//SystemVerilog
module usb_sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst_b,
    input wire write_en,
    input wire read_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] count;
    
    // 前移后向寄存器
    reg [DATA_WIDTH-1:0] data_out_reg;
    reg read_valid;
    
    // 中间寄存器，用于存储将要读出的数据
    reg [DATA_WIDTH-1:0] pre_data_out;
    
    // 修改信号逻辑为线网以减少关键路径
    assign empty = (count == 0);
    assign full = (count == FIFO_DEPTH);
    assign data_out = data_out_reg;
    
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            read_valid <= 0;
            pre_data_out <= 0;
            data_out_reg <= 0;
        end else begin
            // 输出寄存器更新逻辑
            if (read_valid) begin
                data_out_reg <= pre_data_out;
            end
            
            read_valid <= 0;
            
            if (write_en && !full && read_en && !empty) begin
                // 同时读写操作
                mem[wr_ptr] <= data_in;
                pre_data_out <= mem[rd_ptr];
                read_valid <= 1;
                wr_ptr <= wr_ptr + 1;
                rd_ptr <= rd_ptr + 1;
                // 读写同时发生，count不变
            end else begin
                if (write_en && !full) begin
                    // 只写不读
                    mem[wr_ptr] <= data_in;
                    wr_ptr <= wr_ptr + 1;
                    count <= count + 1;
                end
                
                if (read_en && !empty) begin
                    // 只读不写
                    pre_data_out <= mem[rd_ptr];
                    read_valid <= 1;
                    rd_ptr <= rd_ptr + 1;
                    count <= count - 1;
                end
            end
        end
    end
endmodule