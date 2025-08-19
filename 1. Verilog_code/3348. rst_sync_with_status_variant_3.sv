//SystemVerilog
module rst_sync_with_status_pipeline (
    input  wire clock,
    input  wire async_reset_n,
    output wire sync_reset_n,
    output wire reset_active,
    input  wire start,
    input  wire flush,
    output wire valid_out
);
    // Stage 1: Sample async_reset_n and generate first sync
    reg [1:0] sync_ff_stage1;
    reg       valid_stage1;

    // Stage 1 buffer registers for fanout reduction
    reg [1:0] sync_ff_stage1_buf1;
    reg [1:0] sync_ff_stage1_buf2;
    reg       valid_stage1_buf1;
    reg       valid_stage1_buf2;

    // Stage 2: Second sync and output logic
    reg [1:0] sync_ff_stage2;
    reg       valid_stage2;

    // Stage 2 buffer registers for fanout reduction
    reg [1:0] sync_ff_stage2_buf1;
    reg [1:0] sync_ff_stage2_buf2;
    reg       valid_stage2_buf1;
    reg       valid_stage2_buf2;

    // Buffered outputs
    reg b00_stage2;
    reg b0_stage2;
    reg b00_buf;
    reg b0_buf;

    // Flush or reset logic
    wire      pipeline_reset_n = async_reset_n & ~flush;

    // Stage 1: Register async_reset_n and start
    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n) begin
            sync_ff_stage1 <= 2'b00;
            valid_stage1   <= 1'b0;
        end else if (flush) begin
            sync_ff_stage1 <= 2'b00;
            valid_stage1   <= 1'b0;
        end else if (start) begin
            sync_ff_stage1 <= {sync_ff_stage1[0], 1'b1};
            valid_stage1   <= 1'b1;
        end else begin
            sync_ff_stage1 <= sync_ff_stage1;
            valid_stage1   <= valid_stage1;
        end
    end

    // Stage 1 buffering to reduce fanout
    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n) begin
            sync_ff_stage1_buf1 <= 2'b00;
            sync_ff_stage1_buf2 <= 2'b00;
            valid_stage1_buf1   <= 1'b0;
            valid_stage1_buf2   <= 1'b0;
        end else begin
            sync_ff_stage1_buf1 <= sync_ff_stage1;
            sync_ff_stage1_buf2 <= sync_ff_stage1;
            valid_stage1_buf1   <= valid_stage1;
            valid_stage1_buf2   <= valid_stage1;
        end
    end

    // Stage 2: Register intermediate sync and valid, using buffered stage1
    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n) begin
            sync_ff_stage2 <= 2'b00;
            valid_stage2   <= 1'b0;
        end else if (flush) begin
            sync_ff_stage2 <= 2'b00;
            valid_stage2   <= 1'b0;
        end else begin
            sync_ff_stage2 <= sync_ff_stage1_buf1;
            valid_stage2   <= valid_stage1_buf1;
        end
    end

    // Stage 2 buffering to reduce fanout
    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n) begin
            sync_ff_stage2_buf1 <= 2'b00;
            sync_ff_stage2_buf2 <= 2'b00;
            valid_stage2_buf1   <= 1'b0;
            valid_stage2_buf2   <= 1'b0;
        end else begin
            sync_ff_stage2_buf1 <= sync_ff_stage2;
            sync_ff_stage2_buf2 <= sync_ff_stage2;
            valid_stage2_buf1   <= valid_stage2;
            valid_stage2_buf2   <= valid_stage2;
        end
    end

    // Buffer the outputs for b00 and b0 driven by sync_ff_stage2_buf1 to reduce fanout
    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n) begin
            b00_stage2 <= 1'b0;
            b0_stage2  <= 1'b0;
            b00_buf    <= 1'b0;
            b0_buf     <= 1'b0;
        end else begin
            b00_stage2 <= sync_ff_stage2_buf1[1];
            b0_stage2  <= sync_ff_stage2_buf1[0];
            b00_buf    <= b00_stage2;
            b0_buf     <= b0_stage2;
        end
    end

    // Outputs from buffered pipeline stage 2
    assign sync_reset_n = b00_buf;
    assign reset_active = ~b00_buf;
    assign valid_out    = valid_stage2_buf1;

endmodule