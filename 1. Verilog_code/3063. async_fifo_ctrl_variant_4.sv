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

    reg [PTR_WIDTH:0] wr_ptr;
    reg [PTR_WIDTH:0] rd_ptr_sync_ff1, rd_ptr_sync_ff2;
    wire [PTR_WIDTH:0] wr_ptr_next;
    wire wr_ptr_inc;
    
    reg [PTR_WIDTH:0] rd_ptr;
    reg [PTR_WIDTH:0] wr_ptr_sync_ff1, wr_ptr_sync_ff2;
    wire [PTR_WIDTH:0] rd_ptr_next;
    wire rd_ptr_inc;
    
    assign wr_ptr_inc = wr_en && !full;
    assign wr_ptr_next = wr_ptr + 1'b1;
    assign rd_ptr_inc = rd_en && !empty;
    assign rd_ptr_next = rd_ptr + 1'b1;
    
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr_sync_ff1 <= 0;
            rd_ptr_sync_ff2 <= 0;
        end
        else if (wr_ptr_inc) begin
            wr_ptr <= wr_ptr_next;
            rd_ptr_sync_ff1 <= rd_ptr;
            rd_ptr_sync_ff2 <= rd_ptr_sync_ff1;
        end
        else begin
            wr_ptr <= wr_ptr;
            rd_ptr_sync_ff1 <= rd_ptr;
            rd_ptr_sync_ff2 <= rd_ptr_sync_ff1;
        end
    end
    
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            wr_ptr_sync_ff1 <= 0;
            wr_ptr_sync_ff2 <= 0;
        end
        else if (rd_ptr_inc) begin
            rd_ptr <= rd_ptr_next;
            wr_ptr_sync_ff1 <= wr_ptr;
            wr_ptr_sync_ff2 <= wr_ptr_sync_ff1;
        end
        else begin
            rd_ptr <= rd_ptr;
            wr_ptr_sync_ff1 <= wr_ptr;
            wr_ptr_sync_ff2 <= wr_ptr_sync_ff1;
        end
    end
    
    always @(*) begin
        full = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr_sync_ff2[PTR_WIDTH-1:0]) && 
               (wr_ptr[PTR_WIDTH] != rd_ptr_sync_ff2[PTR_WIDTH]);
        empty = (wr_ptr_sync_ff2 == rd_ptr);
        level = wr_ptr_sync_ff2 - rd_ptr;
    end

endmodule