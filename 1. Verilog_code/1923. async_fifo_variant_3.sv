//SystemVerilog
module async_fifo #(parameter DW=16, DEPTH=8) (
    input  wire              wr_clk,
    input  wire              rd_clk,
    input  wire              rst,
    input  wire              wr_en,
    input  wire              rd_en,
    input  wire [DW-1:0]     din,
    output reg  [DW-1:0]     dout,
    output wire              full,
    output wire              empty
);
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Memory array
    reg [DW-1:0] mem [0:DEPTH-1];

    // Write pointer signals
    reg [ADDR_WIDTH:0] wr_ptr_bin;
    reg [ADDR_WIDTH:0] wr_ptr_gray;

    // Read pointer signals
    reg [ADDR_WIDTH:0] rd_ptr_bin;
    reg [ADDR_WIDTH:0] rd_ptr_gray;

    // Synchronized pointers
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync_wrclk;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_rdclk;

    // Internal wires for next pointer values
    wire [ADDR_WIDTH:0] wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next;
    wire [ADDR_WIDTH:0] rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next;

    assign wr_ptr_bin_next  = wr_ptr_bin + 1'b1;
    assign wr_ptr_gray_next = wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);

    assign rd_ptr_bin_next  = rd_ptr_bin + 1'b1;
    assign rd_ptr_gray_next = rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);

    // --- Write domain logic ---

    // Write pointer binary update
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            wr_ptr_bin <= { (ADDR_WIDTH+1) {1'b0} };
        else if (wr_en && !full)
            wr_ptr_bin <= wr_ptr_bin_next;
    end

    // Write pointer gray update
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            wr_ptr_gray <= { (ADDR_WIDTH+1) {1'b0} };
        else if (wr_en && !full)
            wr_ptr_gray <= wr_ptr_gray_next;
    end

    // Memory write
    always @(posedge wr_clk) begin
        if (wr_en && !full)
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;
    end

    // Synchronize read pointer into write clock domain
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            rd_ptr_gray_sync_wrclk <= { (ADDR_WIDTH+1) {1'b0} };
        else
            rd_ptr_gray_sync_wrclk <= rd_ptr_gray;
    end

    // --- Read domain logic ---

    // Read pointer binary update
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            rd_ptr_bin <= { (ADDR_WIDTH+1) {1'b0} };
        else if (rd_en && !empty)
            rd_ptr_bin <= rd_ptr_bin_next;
    end

    // Read pointer gray update
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            rd_ptr_gray <= { (ADDR_WIDTH+1) {1'b0} };
        else if (rd_en && !empty)
            rd_ptr_gray <= rd_ptr_gray_next;
    end

    // Memory read
    always @(posedge rd_clk) begin
        if (rd_en && !empty)
            dout <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
    end

    // dout reset
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            dout <= {DW{1'b0}};
    end

    // Synchronize write pointer into read clock domain
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            wr_ptr_gray_sync_rdclk <= { (ADDR_WIDTH+1) {1'b0} };
        else
            wr_ptr_gray_sync_rdclk <= wr_ptr_gray;
    end

    // --- Status flags ---

    // Full detection
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync_wrclk[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync_wrclk[ADDR_WIDTH-2:0]});

    // Empty detection
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync_rdclk);

endmodule