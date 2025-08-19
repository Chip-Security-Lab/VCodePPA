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
    reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] wr_ptr, rd_ptr;
    
    // Write logic (input clock domain)
    always @(posedge src_clk) begin
        if (rst) wr_ptr <= 0;
        else if (wr_en && !full) begin
            fifo[wr_ptr[$clog2(FIFO_DEPTH)-1:0]] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // Read logic (output clock domain) with RGB conversion
    always @(posedge dst_clk) begin
        if (rst) begin
            rd_ptr <= 0;
            data_out <= 0;
        end else if (rd_en && !empty) begin
            data_out <= {fifo[rd_ptr[$clog2(FIFO_DEPTH)-1:0]][23:19], 
                         fifo[rd_ptr[$clog2(FIFO_DEPTH)-1:0]][15:10],
                         fifo[rd_ptr[$clog2(FIFO_DEPTH)-1:0]][7:3]};
            rd_ptr <= rd_ptr + 1;
        end
    end
    
    assign full = (wr_ptr[$clog2(FIFO_DEPTH)-1:0] == rd_ptr[$clog2(FIFO_DEPTH)-1:0]) && 
                 (wr_ptr[$clog2(FIFO_DEPTH)] != rd_ptr[$clog2(FIFO_DEPTH)]);
    assign empty = (wr_ptr == rd_ptr);
endmodule