//SystemVerilog
module cdc_fifo_ctrl #(
    parameter DEPTH = 8
)(
    input  wire                        wr_clk,
    input  wire                        rd_clk,
    input  wire                        reset,
    input  wire                        write,
    input  wire                        read,
    output wire                        full,
    output wire                        empty,
    output reg  [$clog2(DEPTH)-1:0]    wptr,
    output reg  [$clog2(DEPTH)-1:0]    rptr
);

    // Buffered $clog2(DEPTH)
    reg [$clog2(DEPTH)-1:0] clog2_depth_buf;

    // Stage 1: Write Pointer Pipeline
    reg [$clog2(DEPTH)-1:0] wptr_bin_stage1;      // Stage 1: Next binary pointer
    reg [$clog2(DEPTH)-1:0] wptr_bin_stage2;      // Stage 2: Registered binary pointer

    // Buffer for wptr_bin_stage1 fanout
    reg [$clog2(DEPTH)-1:0] wptr_bin_stage1_buf1;
    reg [$clog2(DEPTH)-1:0] wptr_bin_stage1_buf2;

    // Buffer for wptr_bin_stage2 fanout
    reg [$clog2(DEPTH)-1:0] wptr_bin_stage2_buf1;
    reg [$clog2(DEPTH)-1:0] wptr_bin_stage2_buf2;

    reg [$clog2(DEPTH)-1:0] wptr_gray_stage1;     // Stage 1: Gray code conversion
    reg [$clog2(DEPTH)-1:0] wptr_gray_stage2;     // Stage 2: Registered Gray code

    // Stage 2: Read Pointer Pipeline
    reg [$clog2(DEPTH)-1:0] rptr_bin_stage1;      // Stage 1: Next binary pointer
    reg [$clog2(DEPTH)-1:0] rptr_bin_stage2;      // Stage 2: Registered binary pointer

    // Buffer for rptr_bin_stage1 fanout
    reg [$clog2(DEPTH)-1:0] rptr_bin_stage1_buf1;
    reg [$clog2(DEPTH)-1:0] rptr_bin_stage1_buf2;

    // Buffer for rptr_bin_stage2 fanout
    reg [$clog2(DEPTH)-1:0] rptr_bin_stage2_buf1;
    reg [$clog2(DEPTH)-1:0] rptr_bin_stage2_buf2;

    reg [$clog2(DEPTH)-1:0] rptr_gray_stage1;     // Stage 1: Gray code conversion
    reg [$clog2(DEPTH)-1:0] rptr_gray_stage2;     // Stage 2: Registered Gray code

    // Synchronizer for wr->rd domain
    reg [$clog2(DEPTH)-1:0] wptr_gray_sync1_rd;
    reg [$clog2(DEPTH)-1:0] wptr_gray_sync2_rd;

    // Synchronizer for rd->wr domain
    reg [$clog2(DEPTH)-1:0] rptr_gray_sync1_wr;
    reg [$clog2(DEPTH)-1:0] rptr_gray_sync2_wr;

    // Buffer for $clog2(DEPTH) (used in comparators, Gray code, etc.)
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            clog2_depth_buf <= {$clog2(DEPTH){1'b0}};
        end else begin
            clog2_depth_buf <= $clog2(DEPTH);
        end
    end

    // Write Pointer Pipeline (wr_clk domain) with buffer registers
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wptr_bin_stage1     <= 0;
            wptr_bin_stage2     <= 0;
            wptr_bin_stage1_buf1<= 0;
            wptr_bin_stage1_buf2<= 0;
            wptr_bin_stage2_buf1<= 0;
            wptr_bin_stage2_buf2<= 0;
            wptr_gray_stage1    <= 0;
            wptr_gray_stage2    <= 0;
            wptr                <= 0;
        end else begin
            if (write && !full) begin
                wptr_bin_stage1 <= wptr_bin_stage2 + 1'b1;
            end else begin
                wptr_bin_stage1 <= wptr_bin_stage2;
            end
            wptr_bin_stage1_buf1 <= wptr_bin_stage1;
            wptr_bin_stage1_buf2 <= wptr_bin_stage1;
            wptr_bin_stage2      <= wptr_bin_stage1_buf1;
            wptr_bin_stage2_buf1 <= wptr_bin_stage2;
            wptr_bin_stage2_buf2 <= wptr_bin_stage2;
            wptr_gray_stage1     <= wptr_bin_stage1_buf2 ^ (wptr_bin_stage1_buf2 >> 1);
            wptr_gray_stage2     <= wptr_gray_stage1;
            if (write && !full) begin
                wptr <= wptr_bin_stage1_buf2;
            end
        end
    end

    // Read Pointer Pipeline (rd_clk domain) with buffer registers
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rptr_bin_stage1     <= 0;
            rptr_bin_stage2     <= 0;
            rptr_bin_stage1_buf1<= 0;
            rptr_bin_stage1_buf2<= 0;
            rptr_bin_stage2_buf1<= 0;
            rptr_bin_stage2_buf2<= 0;
            rptr_gray_stage1    <= 0;
            rptr_gray_stage2    <= 0;
            rptr                <= 0;
        end else begin
            if (read && !empty) begin
                rptr_bin_stage1 <= rptr_bin_stage2 + 1'b1;
            end else begin
                rptr_bin_stage1 <= rptr_bin_stage2;
            end
            rptr_bin_stage1_buf1 <= rptr_bin_stage1;
            rptr_bin_stage1_buf2 <= rptr_bin_stage1;
            rptr_bin_stage2      <= rptr_bin_stage1_buf1;
            rptr_bin_stage2_buf1 <= rptr_bin_stage2;
            rptr_bin_stage2_buf2 <= rptr_bin_stage2;
            rptr_gray_stage1     <= rptr_bin_stage1_buf2 ^ (rptr_bin_stage1_buf2 >> 1);
            rptr_gray_stage2     <= rptr_gray_stage1;
            if (read && !empty) begin
                rptr <= rptr_bin_stage1_buf2;
            end
        end
    end

    // Write Pointer Gray Synchronizer (wr_gray -> rd_clk domain)
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            wptr_gray_sync1_rd <= 0;
            wptr_gray_sync2_rd <= 0;
        end else begin
            wptr_gray_sync1_rd <= wptr_gray_stage2;
            wptr_gray_sync2_rd <= wptr_gray_sync1_rd;
        end
    end

    // Read Pointer Gray Synchronizer (rd_gray -> wr_clk domain)
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            rptr_gray_sync1_wr <= 0;
            rptr_gray_sync2_wr <= 0;
        end else begin
            rptr_gray_sync1_wr <= rptr_gray_stage2;
            rptr_gray_sync2_wr <= rptr_gray_sync1_wr;
        end
    end

    // FIFO Full and Empty Logic using buffered signals
    wire [$clog2(DEPTH)-1:0] rptr_gray_sync2_wr_buf;
    reg  [$clog2(DEPTH)-1:0] rptr_gray_sync2_wr_buf_reg;
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            rptr_gray_sync2_wr_buf_reg <= 0;
        end else begin
            rptr_gray_sync2_wr_buf_reg <= rptr_gray_sync2_wr;
        end
    end
    assign rptr_gray_sync2_wr_buf = rptr_gray_sync2_wr_buf_reg;

    wire [$clog2(DEPTH)-1:0] wptr_gray_sync2_rd_buf;
    reg  [$clog2(DEPTH)-1:0] wptr_gray_sync2_rd_buf_reg;
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            wptr_gray_sync2_rd_buf_reg <= 0;
        end else begin
            wptr_gray_sync2_rd_buf_reg <= wptr_gray_sync2_rd;
        end
    end
    assign wptr_gray_sync2_rd_buf = wptr_gray_sync2_rd_buf_reg;

    // Full: Write pointer Gray equals Read pointer Gray synchronized into wr_clk domain with MSBs inverted
    assign full = (wptr_gray_stage2 == {~rptr_gray_sync2_wr_buf[$clog2(DEPTH)-1:$clog2(DEPTH)-2], rptr_gray_sync2_wr_buf[$clog2(DEPTH)-3:0]});

    // Empty: Read pointer Gray equals Write pointer Gray synchronized into rd_clk domain
    assign empty = (rptr_gray_stage2 == wptr_gray_sync2_rd_buf);

endmodule