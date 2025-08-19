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
    output reg [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);
    // IEEE 1364-2005 Verilog标准
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] count;
    
    assign empty = (count == 0);
    assign full = (count == FIFO_DEPTH);
    
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            // 提取操作条件为case语句
            case ({write_en & ~full, read_en & ~empty})
                2'b11: begin // 同时读写操作
                    mem[wr_ptr] <= data_in;
                    data_out <= mem[rd_ptr];
                    wr_ptr <= wr_ptr + 1;
                    rd_ptr <= rd_ptr + 1;
                    // 计数器保持不变
                end
                2'b10: begin // 只写不读
                    mem[wr_ptr] <= data_in;
                    wr_ptr <= wr_ptr + 1;
                    count <= count + 1;
                end
                2'b01: begin // 只读不写
                    data_out <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    count <= count - 1;
                end
                default: begin // 无操作
                    // 保持当前状态
                end
            endcase
        end
    end
endmodule