//SystemVerilog
module async_fifo #(parameter DW=16, DEPTH=8) (
    input wr_clk,
    input rd_clk,
    input rst,
    input wr_en,
    input rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output full,
    output empty
);

    // FIFO memory array
    reg [DW-1:0] mem [0:DEPTH-1];

    // Write and read pointers (binary and gray)
    reg [2:0] wr_ptr;
    reg [2:0] wr_ptr_gray;
    reg [2:0] rd_ptr;
    reg [2:0] rd_ptr_gray;

    // Synchronized pointers for cross-clock domain
    reg [2:0] rd_ptr_gray_sync_wrclk;
    reg [2:0] wr_ptr_gray_sync_rdclk;

    // Status flags
    reg full_reg;
    reg empty_reg;

    //===========================================================
    // Write Side Logic (wr_clk domain)
    //===========================================================

    // Write data into FIFO memory
    // Handles: FIFO write operation
    always @(posedge wr_clk) begin
        if (wr_en && !full)
            mem[wr_ptr] <= din;
    end

    // Write pointer update (binary)
    // Handles: Write pointer increment/reset
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            wr_ptr <= 3'd0;
        else if (wr_en && !full)
            wr_ptr <= wr_ptr + 1'b1;
    end

    // Write pointer update (gray code)
    // Handles: Write pointer gray conversion
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            wr_ptr_gray <= 3'd0;
        else if (wr_en && !full)
            wr_ptr_gray <= (wr_ptr + 1'b1) ^ ((wr_ptr + 1'b1) >> 1);
        else
            wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
    end

    // Synchronize read pointer gray into write clock domain
    // Handles: Cross-domain pointer synchronization (rd->wr)
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            rd_ptr_gray_sync_wrclk <= 3'd0;
        else
            rd_ptr_gray_sync_wrclk <= rd_ptr_gray;
    end

    // Full flag generation
    // Handles: FIFO full detection
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            full_reg <= 1'b0;
        else
            full_reg <= (wr_ptr_gray == {~rd_ptr_gray_sync_wrclk[2], rd_ptr_gray_sync_wrclk[1:0]});
    end

    assign full = full_reg;

    //===========================================================
    // Read Side Logic (rd_clk domain)
    //===========================================================

    // Read pointer update (binary)
    // Handles: Read pointer increment/reset
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            rd_ptr <= 3'd0;
        else if (rd_en && !empty)
            rd_ptr <= rd_ptr + 1'b1;
    end

    // Read pointer update (gray code)
    // Handles: Read pointer gray conversion
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            rd_ptr_gray <= 3'd0;
        else if (rd_en && !empty)
            rd_ptr_gray <= (rd_ptr + 1'b1) ^ ((rd_ptr + 1'b1) >> 1);
        else
            rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
    end

    // Synchronize write pointer gray into read clock domain
    // Handles: Cross-domain pointer synchronization (wr->rd)
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            wr_ptr_gray_sync_rdclk <= 3'd0;
        else
            wr_ptr_gray_sync_rdclk <= wr_ptr_gray;
    end

    // Read data from FIFO memory
    // Handles: FIFO read operation
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            dout <= {DW{1'b0}};
        else if (rd_en && !empty)
            dout <= mem[rd_ptr];
    end

    // Empty flag generation
    // Handles: FIFO empty detection
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            empty_reg <= 1'b1;
        else
            empty_reg <= (rd_ptr_gray == wr_ptr_gray_sync_rdclk);
    end

    assign empty = empty_reg;

endmodule