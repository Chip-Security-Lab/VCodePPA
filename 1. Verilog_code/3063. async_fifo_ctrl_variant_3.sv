//SystemVerilog
module async_fifo_ctrl #(
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input wire wr_clk, rd_clk, rst_n,
    input wire wr_en, rd_en,
    output wire full, empty,
    output wire [PTR_WIDTH:0] level
);

    // Sequential logic signals
    reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
    reg [PTR_WIDTH:0] wr_ptr_sync, rd_ptr_sync;
    reg [PTR_WIDTH:0] wr_ptr_buf, rd_ptr_buf;
    reg [PTR_WIDTH:0] wr_ptr_sync_buf, rd_ptr_sync_buf;
    
    // Write pointer sequential logic with buffering
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            wr_ptr_buf <= 0;
            rd_ptr_sync <= 0;
            rd_ptr_sync_buf <= 0;
        end else begin
            rd_ptr_sync <= rd_ptr;
            rd_ptr_sync_buf <= rd_ptr_sync;
            if (wr_en && !full) begin
                wr_ptr <= wr_ptr + 1'b1;
                wr_ptr_buf <= wr_ptr;
            end
        end
    end
    
    // Read pointer sequential logic with buffering
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            rd_ptr_buf <= 0;
            wr_ptr_sync <= 0;
            wr_ptr_sync_buf <= 0;
        end else begin
            wr_ptr_sync <= wr_ptr;
            wr_ptr_sync_buf <= wr_ptr_sync;
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
                rd_ptr_buf <= rd_ptr;
            end
        end
    end
    
    // Combinational logic for status flags and level calculation
    assign full = (wr_ptr_buf[PTR_WIDTH-1:0] == rd_ptr_sync_buf[PTR_WIDTH-1:0]) && 
                 (wr_ptr_buf[PTR_WIDTH] != rd_ptr_sync_buf[PTR_WIDTH]);
    
    assign empty = (wr_ptr_sync_buf == rd_ptr_buf);
    
    assign level = wr_ptr_sync_buf - rd_ptr_buf;
    
endmodule