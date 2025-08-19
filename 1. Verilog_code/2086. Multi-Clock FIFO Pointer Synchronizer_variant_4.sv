//SystemVerilog
// Hierarchical FIFO pointer synchronization, pipelined

module fifo_ptr_sync_pipelined #(
    parameter ADDR_WIDTH = 5
)(
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  reset,
    input  wire                  write,
    input  wire                  read,
    output wire                  full,
    output wire                  empty,
    output wire [ADDR_WIDTH-1:0] wr_addr,
    output wire [ADDR_WIDTH-1:0] rd_addr
);

    // Write pointer pipeline
    wire [ADDR_WIDTH:0] wr_ptr_bin_out;
    wire [ADDR_WIDTH:0] wr_ptr_gray_out;
    wire                write_valid_out;

    fifo_ptr_pipeline #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_wr_ptr_pipeline (
        .clk           (wr_clk),
        .reset         (reset),
        .enable        (write & ~full),
        .feedback_bin  (wr_ptr_bin_out),
        .ptr_bin_out   (wr_ptr_bin_out),
        .ptr_gray_out  (wr_ptr_gray_out),
        .valid_out     (write_valid_out)
    );

    // Read pointer pipeline
    wire [ADDR_WIDTH:0] rd_ptr_bin_out;
    wire [ADDR_WIDTH:0] rd_ptr_gray_out;
    wire                read_valid_out;

    fifo_ptr_pipeline #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_rd_ptr_pipeline (
        .clk           (rd_clk),
        .reset         (reset),
        .enable        (read & ~empty),
        .feedback_bin  (rd_ptr_bin_out),
        .ptr_bin_out   (rd_ptr_bin_out),
        .ptr_gray_out  (rd_ptr_gray_out),
        .valid_out     (read_valid_out)
    );

    // Write pointer Gray synchronization to read clock domain
    wire [ADDR_WIDTH:0] wr_ptr_gray_sync_to_rdclk;

    fifo_gray_sync #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_wr_ptr_gray_sync_to_rdclk (
        .clk        (rd_clk),
        .reset      (reset),
        .gray_in    (wr_ptr_gray_out),
        .gray_sync  (wr_ptr_gray_sync_to_rdclk)
    );

    // Read pointer Gray synchronization to write clock domain
    wire [ADDR_WIDTH:0] rd_ptr_gray_sync_to_wrclk;

    fifo_gray_sync #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_rd_ptr_gray_sync_to_wrclk (
        .clk        (wr_clk),
        .reset      (reset),
        .gray_in    (rd_ptr_gray_out),
        .gray_sync  (rd_ptr_gray_sync_to_wrclk)
    );

    // Full and empty flag generation
    wire full_flag;
    wire empty_flag;

    fifo_flag_gen #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_full_flag_gen (
        .clk           (wr_clk),
        .reset         (reset),
        .local_gray    (wr_ptr_gray_out),
        .remote_gray   (rd_ptr_gray_sync_to_wrclk),
        .flag_out      (full_flag),
        .is_full_empty (1'b1) // 1: full
    );

    fifo_flag_gen #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_empty_flag_gen (
        .clk           (rd_clk),
        .reset         (reset),
        .local_gray    (rd_ptr_gray_out),
        .remote_gray   (wr_ptr_gray_sync_to_rdclk),
        .flag_out      (empty_flag),
        .is_full_empty (1'b0) // 0: empty
    );

    // Address extraction logic
    fifo_addr_reg #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_wr_addr_reg (
        .clk       (wr_clk),
        .reset     (reset),
        .valid_in  (write_valid_out),
        .bin_in    (wr_ptr_bin_out),
        .addr_out  (wr_addr)
    );

    fifo_addr_reg #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_rd_addr_reg (
        .clk       (rd_clk),
        .reset     (reset),
        .valid_in  (read_valid_out),
        .bin_in    (rd_ptr_bin_out),
        .addr_out  (rd_addr)
    );

    assign full  = full_flag;
    assign empty = empty_flag;

endmodule

// =======================
// Pointer Pipeline Submodule
// =======================
// Handles pointer increment, Gray conversion, and 4-stage pipelining

module fifo_ptr_pipeline #(
    parameter ADDR_WIDTH = 5
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  enable,
    input  wire [ADDR_WIDTH:0]   feedback_bin,
    output reg  [ADDR_WIDTH:0]   ptr_bin_out,
    output reg  [ADDR_WIDTH:0]   ptr_gray_out,
    output reg                   valid_out
);
    // Stage registers
    reg [ADDR_WIDTH:0] bin_stage1, bin_stage2, bin_stage3, bin_stage4;
    reg [ADDR_WIDTH:0] gray_stage2, gray_stage3, gray_stage4;
    reg                valid_stage1, valid_stage2, valid_stage3, valid_stage4;

    wire [ADDR_WIDTH:0] bin_next_stage1;
    assign bin_next_stage1 = bin_stage1 + (enable ? 1'b1 : 1'b0);

    wire [ADDR_WIDTH:0] gray_next_stage2;
    assign gray_next_stage2 = (bin_next_stage1 >> 1) ^ bin_next_stage1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bin_stage1      <= { (ADDR_WIDTH+1){1'b0} };
            bin_stage2      <= { (ADDR_WIDTH+1){1'b0} };
            bin_stage3      <= { (ADDR_WIDTH+1){1'b0} };
            bin_stage4      <= { (ADDR_WIDTH+1){1'b0} };
            gray_stage2     <= { (ADDR_WIDTH+1){1'b0} };
            gray_stage3     <= { (ADDR_WIDTH+1){1'b0} };
            gray_stage4     <= { (ADDR_WIDTH+1){1'b0} };
            valid_stage1    <= 1'b0;
            valid_stage2    <= 1'b0;
            valid_stage3    <= 1'b0;
            valid_stage4    <= 1'b0;
        end else begin
            bin_stage1      <= feedback_bin; // feedback for continuous counting
            bin_stage2      <= bin_next_stage1;
            bin_stage3      <= bin_stage2;
            bin_stage4      <= bin_stage3;
            gray_stage2     <= gray_next_stage2;
            gray_stage3     <= gray_stage2;
            gray_stage4     <= gray_stage3;
            valid_stage1    <= 1'b1;
            valid_stage2    <= valid_stage1;
            valid_stage3    <= valid_stage2;
            valid_stage4    <= valid_stage3;
        end
    end

    always @(*) begin
        ptr_bin_out   = bin_stage4;
        ptr_gray_out  = gray_stage4;
        valid_out     = valid_stage4;
    end

endmodule

// =======================
// Gray Pointer Synchronizer Submodule
// =======================
// 2-flop synchronizer for pointer crossing clock domains

module fifo_gray_sync #(
    parameter ADDR_WIDTH = 5
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire [ADDR_WIDTH:0]   gray_in,
    output reg  [ADDR_WIDTH:0]   gray_sync
);
    reg [ADDR_WIDTH:0] sync_stage1, sync_stage2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_stage1 <= { (ADDR_WIDTH+1){1'b0} };
            sync_stage2 <= { (ADDR_WIDTH+1){1'b0} };
        end else begin
            sync_stage1 <= gray_in;
            sync_stage2 <= sync_stage1;
        end
    end

    always @(*) begin
        gray_sync = sync_stage2;
    end
endmodule

// =======================
// Full/Empty Flag Generator Submodule
// =======================
// Generates 'full' or 'empty' status by comparing Gray pointers

module fifo_flag_gen #(
    parameter ADDR_WIDTH = 5
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire [ADDR_WIDTH:0]   local_gray,
    input  wire [ADDR_WIDTH:0]   remote_gray,
    output reg                   flag_out,
    input  wire                  is_full_empty // 1: full, 0: empty
);
    reg flag_stage1, flag_stage2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if (is_full_empty)
                flag_stage1 <= 1'b0;
            else
                flag_stage1 <= 1'b1;

            flag_stage2 <= flag_stage1;
        end else begin
            if (is_full_empty) begin
                // Full condition: local_gray == {~remote_gray[ADDR_WIDTH:ADDR_WIDTH-1], remote_gray[ADDR_WIDTH-2:0]}
                flag_stage1 <= (local_gray == {~remote_gray[ADDR_WIDTH:ADDR_WIDTH-1], remote_gray[ADDR_WIDTH-2:0]});
            end else begin
                // Empty condition: local_gray == remote_gray
                flag_stage1 <= (local_gray == remote_gray);
            end
            flag_stage2 <= flag_stage1;
        end
    end

    always @(*) begin
        flag_out = flag_stage2;
    end
endmodule

// =======================
// Address Register Submodule
// =======================
// Registers the pointer's address portion for output

module fifo_addr_reg #(
    parameter ADDR_WIDTH = 5
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  valid_in,
    input  wire [ADDR_WIDTH:0]   bin_in,
    output reg  [ADDR_WIDTH-1:0] addr_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            addr_out <= {ADDR_WIDTH{1'b0}};
        end else if (valid_in) begin
            addr_out <= bin_in[ADDR_WIDTH-1:0];
        end
    end
endmodule