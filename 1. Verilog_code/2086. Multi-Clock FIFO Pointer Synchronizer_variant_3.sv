//SystemVerilog
module fifo_ptr_sync #(parameter ADDR_WIDTH = 5) (
    input  wire                    wr_clk,
    input  wire                    rd_clk,
    input  wire                    reset,
    input  wire                    write,
    input  wire                    read,
    output wire                    full,
    output wire                    empty,
    output wire [ADDR_WIDTH-1:0]   wr_addr,
    output wire [ADDR_WIDTH-1:0]   rd_addr
);

    // =======================
    // Stage 1: Write Pointer Pipeline
    // =======================
    reg [ADDR_WIDTH:0] wr_bin_stage1, wr_bin_stage2;
    reg [ADDR_WIDTH:0] wr_gray_stage1, wr_gray_stage2;

    wire [ADDR_WIDTH:0] wr_bin_increment;
    wire [ADDR_WIDTH:0] wr_gray_next;

    assign wr_bin_increment = wr_bin_stage1 + (write & ~full);

    // Binary to Gray code conversion
    assign wr_gray_next = (wr_bin_increment >> 1) ^ wr_bin_increment;

    // Stage 1: Update binary write pointer
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wr_bin_stage1  <= { (ADDR_WIDTH+1) {1'b0} };
            wr_gray_stage1 <= { (ADDR_WIDTH+1) {1'b0} };
        end else begin
            wr_bin_stage1  <= wr_bin_increment;
            wr_gray_stage1 <= wr_gray_next;
        end
    end

    // Stage 2: Pipeline write pointer to improve timing
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wr_bin_stage2  <= { (ADDR_WIDTH+1) {1'b0} };
            wr_gray_stage2 <= { (ADDR_WIDTH+1) {1'b0} };
        end else begin
            wr_bin_stage2  <= wr_bin_stage1;
            wr_gray_stage2 <= wr_gray_stage1;
        end
    end

    // =======================
    // Stage 2: Read Pointer Pipeline
    // =======================
    reg [ADDR_WIDTH:0] rd_bin_stage1, rd_bin_stage2;
    reg [ADDR_WIDTH:0] rd_gray_stage1, rd_gray_stage2;

    wire [ADDR_WIDTH:0] rd_bin_increment;
    wire [ADDR_WIDTH:0] rd_gray_next;

    assign rd_bin_increment = rd_bin_stage1 + (read & ~empty);

    // Binary to Gray code conversion
    assign rd_gray_next = (rd_bin_increment >> 1) ^ rd_bin_increment;

    // Stage 1: Update binary read pointer
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rd_bin_stage1  <= { (ADDR_WIDTH+1) {1'b0} };
            rd_gray_stage1 <= { (ADDR_WIDTH+1) {1'b0} };
        end else begin
            rd_bin_stage1  <= rd_bin_increment;
            rd_gray_stage1 <= rd_gray_next;
        end
    end

    // Stage 2: Pipeline read pointer to improve timing
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rd_bin_stage2  <= { (ADDR_WIDTH+1) {1'b0} };
            rd_gray_stage2 <= { (ADDR_WIDTH+1) {1'b0} };
        end else begin
            rd_bin_stage2  <= rd_bin_stage1;
            rd_gray_stage2 <= rd_gray_stage1;
        end
    end

    // =======================
    // Stage 3: Pointer Synchronization (Double-Flop)
    // =======================
    reg [ADDR_WIDTH:0] wr_gray_sync_rdclk_1, wr_gray_sync_rdclk_2;
    reg [ADDR_WIDTH:0] rd_gray_sync_wrclk_1, rd_gray_sync_wrclk_2;

    // Write pointer synchronized into read clock domain
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            wr_gray_sync_rdclk_1 <= { (ADDR_WIDTH+1) {1'b0} };
            wr_gray_sync_rdclk_2 <= { (ADDR_WIDTH+1) {1'b0} };
        end else begin
            wr_gray_sync_rdclk_1 <= wr_gray_stage2;
            wr_gray_sync_rdclk_2 <= wr_gray_sync_rdclk_1;
        end
    end

    // Read pointer synchronized into write clock domain
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            rd_gray_sync_wrclk_1 <= { (ADDR_WIDTH+1) {1'b0} };
            rd_gray_sync_wrclk_2 <= { (ADDR_WIDTH+1) {1'b0} };
        end else begin
            rd_gray_sync_wrclk_1 <= rd_gray_stage2;
            rd_gray_sync_wrclk_2 <= rd_gray_sync_wrclk_1;
        end
    end

    // =======================
    // Stage 4: Address Extraction
    // =======================
    assign wr_addr = wr_bin_stage2[ADDR_WIDTH-1:0];
    assign rd_addr = rd_bin_stage2[ADDR_WIDTH-1:0];

    // =======================
    // Stage 5: Full/Empty Logic (Pipelined)
    // =======================
    // Full flag logic in write clock domain, synchronized read pointer
    reg [ADDR_WIDTH:0] rd_gray_sync_wrclk_2_inv;
    reg [ADDR_WIDTH:0] full_sub_result;
    reg                full_flag;

    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            rd_gray_sync_wrclk_2_inv <= { (ADDR_WIDTH+1) {1'b0} };
            full_sub_result          <= { (ADDR_WIDTH+1) {1'b0} };
            full_flag                <= 1'b0;
        end else begin
            rd_gray_sync_wrclk_2_inv <= ~rd_gray_sync_wrclk_2 + 1'b1;
            full_sub_result          <= wr_gray_stage2 + rd_gray_sync_wrclk_2_inv;
            full_flag                <= (full_sub_result == {1'b1, {ADDR_WIDTH{1'b0}}});
        end
    end

    // Empty flag logic in read clock domain, synchronized write pointer
    reg [ADDR_WIDTH:0] wr_gray_sync_rdclk_2_inv;
    reg [ADDR_WIDTH:0] empty_sub_result;
    reg                empty_flag;

    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            wr_gray_sync_rdclk_2_inv <= { (ADDR_WIDTH+1) {1'b0} };
            empty_sub_result         <= { (ADDR_WIDTH+1) {1'b0} };
            empty_flag               <= 1'b1;
        end else begin
            wr_gray_sync_rdclk_2_inv <= ~wr_gray_sync_rdclk_2 + 1'b1;
            empty_sub_result         <= rd_gray_stage2 + wr_gray_sync_rdclk_2_inv;
            empty_flag               <= (empty_sub_result == { (ADDR_WIDTH+1) {1'b0} });
        end
    end

    assign full  = full_flag;
    assign empty = empty_flag;

endmodule