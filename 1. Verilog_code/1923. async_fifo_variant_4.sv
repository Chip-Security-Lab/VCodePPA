//SystemVerilog
module async_fifo_pipelined #(
    parameter DATA_WIDTH = 16,
    parameter FIFO_DEPTH = 8
)(
    input                         wr_clk,
    input                         rd_clk,
    input                         rst,
    input                         wr_en,
    input                         rd_en,
    input      [DATA_WIDTH-1:0]   din,
    output reg [DATA_WIDTH-1:0]   dout,
    output                        full,
    output                        empty
);

    // FIFO Storage
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    // Write-side pipeline
    reg [2:0] wr_ptr_stage0, wr_ptr_stage1, wr_ptr_stage2; // pointer pipeline
    reg [2:0] wr_ptr_gray_stage0, wr_ptr_gray_stage1, wr_ptr_gray_stage2; // gray code pipeline

    // Read-side pipeline
    reg [2:0] rd_ptr_stage0, rd_ptr_stage1, rd_ptr_stage2;
    reg [2:0] rd_ptr_gray_stage0, rd_ptr_gray_stage1, rd_ptr_gray_stage2;

    // Write-side valid pipeline
    reg wr_valid_stage0, wr_valid_stage1, wr_valid_stage2;

    // Read-side valid pipeline
    reg rd_valid_stage0, rd_valid_stage1, rd_valid_stage2;

    // Output data pipeline
    reg [DATA_WIDTH-1:0] dout_stage0, dout_stage1, dout_stage2;
    reg dout_valid_stage0, dout_valid_stage1, dout_valid_stage2;

    // Cross-domain pointer synchronization
    reg [2:0] rd_ptr_gray_sync_wr_stage0, rd_ptr_gray_sync_wr_stage1, rd_ptr_gray_sync_wr_stage2; // to wr_clk
    reg [2:0] wr_ptr_gray_sync_rd_stage0, wr_ptr_gray_sync_rd_stage1, wr_ptr_gray_sync_rd_stage2; // to rd_clk

    // Full/Empty status pipeline
    reg full_stage0, full_stage1, full_stage2;
    reg empty_stage0, empty_stage1, empty_stage2;

    //======================================================================
    // Write Pipeline (wr_clk domain)
    //======================================================================

    // Stage 0: Write data and pointer update
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_stage0      <= 3'd0;
            wr_ptr_gray_stage0 <= 3'd0;
            wr_valid_stage0    <= 1'b0;
        end else begin
            if (wr_en && !full) begin
                fifo_mem[wr_ptr_stage0] <= din;
                wr_ptr_stage0           <= wr_ptr_stage0 + 1'b1;
                wr_ptr_gray_stage0      <= (wr_ptr_stage0 + 1'b1) ^ ((wr_ptr_stage0 + 1'b1) >> 1);
                wr_valid_stage0         <= 1'b1;
            end else begin
                wr_ptr_stage0      <= wr_ptr_stage0;
                wr_ptr_gray_stage0 <= wr_ptr_gray_stage0;
                wr_valid_stage0    <= 1'b0;
            end
        end
    end

    // Stage 1: Pipeline register
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_stage1      <= 3'd0;
            wr_ptr_gray_stage1 <= 3'd0;
            wr_valid_stage1    <= 1'b0;
        end else begin
            wr_ptr_stage1      <= wr_ptr_stage0;
            wr_ptr_gray_stage1 <= wr_ptr_gray_stage0;
            wr_valid_stage1    <= wr_valid_stage0;
        end
    end

    // Stage 2: Pipeline register
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_stage2      <= 3'd0;
            wr_ptr_gray_stage2 <= 3'd0;
            wr_valid_stage2    <= 1'b0;
        end else begin
            wr_ptr_stage2      <= wr_ptr_stage1;
            wr_ptr_gray_stage2 <= wr_ptr_gray_stage1;
            wr_valid_stage2    <= wr_valid_stage1;
        end
    end

    //======================================================================
    // Read Pipeline (rd_clk domain)
    //======================================================================

    // Stage 0: Read data and pointer update
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_stage0      <= 3'd0;
            rd_ptr_gray_stage0 <= 3'd0;
            rd_valid_stage0    <= 1'b0;
            dout_stage0        <= {DATA_WIDTH{1'b0}};
            dout_valid_stage0  <= 1'b0;
        end else begin
            if (rd_en && !empty) begin
                dout_stage0        <= fifo_mem[rd_ptr_stage0];
                dout_valid_stage0  <= 1'b1;
                rd_ptr_stage0      <= rd_ptr_stage0 + 1'b1;
                rd_ptr_gray_stage0 <= (rd_ptr_stage0 + 1'b1) ^ ((rd_ptr_stage0 + 1'b1) >> 1);
                rd_valid_stage0    <= 1'b1;
            end else begin
                dout_stage0        <= dout_stage0;
                dout_valid_stage0  <= 1'b0;
                rd_ptr_stage0      <= rd_ptr_stage0;
                rd_ptr_gray_stage0 <= rd_ptr_gray_stage0;
                rd_valid_stage0    <= 1'b0;
            end
        end
    end

    // Stage 1: Pipeline register
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_stage1      <= 3'd0;
            rd_ptr_gray_stage1 <= 3'd0;
            rd_valid_stage1    <= 1'b0;
            dout_stage1        <= {DATA_WIDTH{1'b0}};
            dout_valid_stage1  <= 1'b0;
        end else begin
            rd_ptr_stage1      <= rd_ptr_stage0;
            rd_ptr_gray_stage1 <= rd_ptr_gray_stage0;
            rd_valid_stage1    <= rd_valid_stage0;
            dout_stage1        <= dout_stage0;
            dout_valid_stage1  <= dout_valid_stage0;
        end
    end

    // Stage 2: Pipeline register
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_stage2      <= 3'd0;
            rd_ptr_gray_stage2 <= 3'd0;
            rd_valid_stage2    <= 1'b0;
            dout_stage2        <= {DATA_WIDTH{1'b0}};
            dout_valid_stage2  <= 1'b0;
        end else begin
            rd_ptr_stage2      <= rd_ptr_stage1;
            rd_ptr_gray_stage2 <= rd_ptr_gray_stage1;
            rd_valid_stage2    <= rd_valid_stage1;
            dout_stage2        <= dout_stage1;
            dout_valid_stage2  <= dout_valid_stage1;
        end
    end

    // Output register
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
        end else if (dout_valid_stage2) begin
            dout <= dout_stage2;
        end
    end

    //======================================================================
    // Pointer Synchronization (Cross-Clock Domain)
    //======================================================================

    // rd_ptr_gray synchronized into wr_clk domain (3-stage pipeline)
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync_wr_stage0 <= 3'd0;
            rd_ptr_gray_sync_wr_stage1 <= 3'd0;
            rd_ptr_gray_sync_wr_stage2 <= 3'd0;
        end else begin
            rd_ptr_gray_sync_wr_stage0 <= rd_ptr_gray_stage2;
            rd_ptr_gray_sync_wr_stage1 <= rd_ptr_gray_sync_wr_stage0;
            rd_ptr_gray_sync_wr_stage2 <= rd_ptr_gray_sync_wr_stage1;
        end
    end

    // wr_ptr_gray synchronized into rd_clk domain (3-stage pipeline)
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync_rd_stage0 <= 3'd0;
            wr_ptr_gray_sync_rd_stage1 <= 3'd0;
            wr_ptr_gray_sync_rd_stage2 <= 3'd0;
        end else begin
            wr_ptr_gray_sync_rd_stage0 <= wr_ptr_gray_stage2;
            wr_ptr_gray_sync_rd_stage1 <= wr_ptr_gray_sync_rd_stage0;
            wr_ptr_gray_sync_rd_stage2 <= wr_ptr_gray_sync_rd_stage1;
        end
    end

    //======================================================================
    // Full/Empty Logic (Structured Pipelined Status)
    //======================================================================

    // Full flag pipeline (wr_clk domain)
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            full_stage0 <= 1'b0;
            full_stage1 <= 1'b0;
            full_stage2 <= 1'b0;
        end else begin
            full_stage0 <= (wr_ptr_gray_stage2 == {~rd_ptr_gray_sync_wr_stage2[2], rd_ptr_gray_sync_wr_stage2[1:0]});
            full_stage1 <= full_stage0;
            full_stage2 <= full_stage1;
        end
    end

    // Empty flag pipeline (rd_clk domain)
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            empty_stage0 <= 1'b1;
            empty_stage1 <= 1'b1;
            empty_stage2 <= 1'b1;
        end else begin
            empty_stage0 <= (rd_ptr_gray_stage2 == wr_ptr_gray_sync_rd_stage2);
            empty_stage1 <= empty_stage0;
            empty_stage2 <= empty_stage1;
        end
    end

    assign full  = full_stage2;
    assign empty = empty_stage2;

endmodule