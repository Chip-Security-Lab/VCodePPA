module cdc_fifo_ctrl #(parameter DEPTH = 8) (
    input wire wr_clk, rd_clk, reset,
    input wire write, read,
    output wire full, empty,
    output reg [$clog2(DEPTH)-1:0] wptr, rptr
);
    reg [$clog2(DEPTH)-1:0] wptr_gray, rptr_gray;
    reg [$clog2(DEPTH)-1:0] wptr_gray_sync1, wptr_gray_sync2;
    reg [$clog2(DEPTH)-1:0] rptr_gray_sync1, rptr_gray_sync2;
    
    // Binary to Gray conversion
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (write && !full) begin
            wptr <= wptr + 1'b1;
            wptr_gray <= (wptr + 1'b1) ^ ((wptr + 1'b1) >> 1);
        end
    end
    
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (read && !empty) begin
            rptr <= rptr + 1'b1;
            rptr_gray <= (rptr + 1'b1) ^ ((rptr + 1'b1) >> 1);
        end
    end
    
    // Synchronizers
    always @(posedge rd_clk) begin
        {wptr_gray_sync1, wptr_gray_sync2} <= {wptr_gray, wptr_gray_sync1};
    end
    
    always @(posedge wr_clk) begin
        {rptr_gray_sync1, rptr_gray_sync2} <= {rptr_gray, rptr_gray_sync1};
    end
    
    // Full and empty generation
    assign full = (wptr_gray == {~rptr_gray_sync2[$clog2(DEPTH)-1:$clog2(DEPTH)-2], 
                               rptr_gray_sync2[$clog2(DEPTH)-3:0]});
    assign empty = (rptr_gray == wptr_gray_sync2);
endmodule