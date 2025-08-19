module fifo_ptr_sync #(parameter ADDR_WIDTH = 5) (
    input wire wr_clk, rd_clk, reset,
    input wire write, read,
    output wire full, empty,
    output reg [ADDR_WIDTH-1:0] wr_addr, rd_addr
);
    // Gray code pointers
    reg [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    
    wire [ADDR_WIDTH:0] wr_ptr_gray_next, rd_ptr_gray_next;
    wire [ADDR_WIDTH:0] wr_ptr_bin_next, rd_ptr_bin_next;
    
    // Binary counter increments
    assign wr_ptr_bin_next = wr_ptr_bin + (write & ~full);
    assign rd_ptr_bin_next = rd_ptr_bin + (read & ~empty);
    
    // Binary to Gray conversion
    assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;
    assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;
    
    // Write pointer logic
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else begin
            wr_ptr_bin <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end
    
    // Read pointer logic
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else begin
            rd_ptr_bin <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end
    
    // Synchronize pointers
    always @(posedge rd_clk) begin
        {wr_ptr_gray_sync2, wr_ptr_gray_sync1} <= {wr_ptr_gray_sync1, wr_ptr_gray};
    end
    
    always @(posedge wr_clk) begin
        {rd_ptr_gray_sync2, rd_ptr_gray_sync1} <= {rd_ptr_gray_sync1, rd_ptr_gray};
    end
    
    // Extract memory addresses
    always @(*) begin
        wr_addr = wr_ptr_bin[ADDR_WIDTH-1:0];
        rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];
    end
    
    // Full and empty generation
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], 
                               rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);
endmodule