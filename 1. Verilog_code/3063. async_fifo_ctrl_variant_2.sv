//SystemVerilog
module async_fifo_ctrl #(
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input wire wr_clk, rd_clk, rst_n,
    input wire wr_en, rd_en,
    output reg full, empty,
    output reg [PTR_WIDTH:0] level
);
    reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
    reg [PTR_WIDTH:0] wr_ptr_sync, rd_ptr_sync;
    wire [PTR_WIDTH:0] wr_ptr_next, rd_ptr_next;
    wire ptr_equal, ptr_msb_diff;
    
    // Optimized pointer update logic
    assign wr_ptr_next = wr_ptr + 1'b1;
    assign rd_ptr_next = rd_ptr + 1'b1;
    
    // Optimized pointer synchronization
    always @(posedge wr_clk or negedge rst_n)
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr_sync <= 0;
        end else begin
            rd_ptr_sync <= rd_ptr;
            if (wr_en && !full)
                wr_ptr <= wr_ptr_next;
        end
    
    always @(posedge rd_clk or negedge rst_n)
        if (!rst_n) begin
            rd_ptr <= 0;
            wr_ptr_sync <= 0;
        end else begin
            wr_ptr_sync <= wr_ptr;
            if (rd_en && !empty)
                rd_ptr <= rd_ptr_next;
        end
    
    // Optimized comparison logic
    assign ptr_equal = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr_sync[PTR_WIDTH-1:0]);
    assign ptr_msb_diff = (wr_ptr[PTR_WIDTH] != rd_ptr_sync[PTR_WIDTH]);
    
    // Optimized status flags and level calculation
    always @(*) begin
        full = ptr_equal && ptr_msb_diff;
        empty = (wr_ptr_sync == rd_ptr);
        level = wr_ptr_sync - rd_ptr;
    end
endmodule