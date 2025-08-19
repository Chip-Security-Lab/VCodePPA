//SystemVerilog
module async_rst_sync_pipeline #(parameter CH=2) (
    input                  clk,
    input                  async_rst,
    input                  start,
    input  [CH-1:0]        ch_in,
    output [CH-1:0]        ch_out,
    output                 valid_out
);

    // Buffered clock distribution
    reg                    clk_buf_stage1;
    reg                    clk_buf_stage2;
    reg                    clk_buf_stage3;

    // Stage 1 registers
    reg  [CH-1:0]          sync0_stage1;
    reg                    valid_stage1;
    reg  [CH-1:0]          sync0_stage1_buf;
    reg                    valid_stage1_buf;

    // Stage 2 registers
    reg  [CH-1:0]          sync1_stage2;
    reg                    valid_stage2;
    reg  [CH-1:0]          sync1_stage2_buf;
    reg                    valid_stage2_buf;

    // Stage 3 registers (output stage)
    reg  [CH-1:0]          sync2_stage3;
    reg                    valid_stage3;

    // Pipeline flush logic
    wire                   flush;
    assign flush = async_rst;

    // Multi-level clock buffer
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            clk_buf_stage1 <= 1'b0;
        end else begin
            clk_buf_stage1 <= 1'b1;
        end
    end

    always @(posedge clk_buf_stage1 or posedge async_rst) begin
        if (async_rst) begin
            clk_buf_stage2 <= 1'b0;
        end else begin
            clk_buf_stage2 <= 1'b1;
        end
    end

    always @(posedge clk_buf_stage2 or posedge async_rst) begin
        if (async_rst) begin
            clk_buf_stage3 <= 1'b0;
        end else begin
            clk_buf_stage3 <= 1'b1;
        end
    end

    // Stage 1: Capture input and valid, then buffer outputs
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            sync0_stage1       <= {CH{1'b0}};
            valid_stage1       <= 1'b0;
        end else if (start) begin
            sync0_stage1       <= ch_in;
            valid_stage1       <= 1'b1;
        end else begin
            valid_stage1       <= 1'b0;
        end
    end

    // Buffer for sync0_stage1 and valid_stage1 (fanout buffer)
    always @(posedge clk_buf_stage1 or posedge async_rst) begin
        if (async_rst) begin
            sync0_stage1_buf   <= {CH{1'b0}};
            valid_stage1_buf   <= 1'b0;
        end else begin
            sync0_stage1_buf   <= sync0_stage1;
            valid_stage1_buf   <= valid_stage1;
        end
    end

    // Stage 2: First synchronizer FF, then buffer outputs
    always @(posedge clk_buf_stage2 or posedge async_rst) begin
        if (async_rst) begin
            sync1_stage2       <= {CH{1'b0}};
            valid_stage2       <= 1'b0;
        end else begin
            sync1_stage2       <= sync0_stage1_buf;
            valid_stage2       <= valid_stage1_buf;
        end
    end

    // Buffer for sync1_stage2 and valid_stage2 (fanout buffer)
    always @(posedge clk_buf_stage3 or posedge async_rst) begin
        if (async_rst) begin
            sync1_stage2_buf   <= {CH{1'b0}};
            valid_stage2_buf   <= 1'b0;
        end else begin
            sync1_stage2_buf   <= sync1_stage2;
            valid_stage2_buf   <= valid_stage2;
        end
    end

    // Stage 3: Second synchronizer FF
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            sync2_stage3       <= {CH{1'b0}};
            valid_stage3       <= 1'b0;
        end else begin
            sync2_stage3       <= sync1_stage2_buf;
            valid_stage3       <= valid_stage2_buf;
        end
    end

    assign ch_out    = sync2_stage3;
    assign valid_out = valid_stage3;

endmodule