//SystemVerilog
// Top-level reset synchronizer with pipelined architecture
module sync_rst_synchronizer (
    input  wire clock,
    input  wire async_reset,
    input  wire sync_reset,
    output wire reset_out,
    input  wire flush,        // Pipeline flush control
    input  wire start,        // Pipeline start control
    output wire valid_out     // Indicates valid reset_out
);

    wire meta_stage1;
    wire meta_stage2;
    wire valid_stage1;
    wire valid_stage2;

    // Pipeline Stage 1: Asynchronous reset synchronization
    async_reset_sync_stage1 u_async_reset_sync_stage1 (
        .clock         (clock),
        .async_reset   (async_reset),
        .sync_reset    (sync_reset),
        .flush         (flush),
        .start         (start),
        .meta_stage1   (meta_stage1),
        .valid_stage1  (valid_stage1)
    );

    // Pipeline Stage 2: Register meta output and propagate valid signal
    reset_pipeline_stage2 u_reset_pipeline_stage2 (
        .clock         (clock),
        .meta_in       (meta_stage1),
        .valid_in      (valid_stage1),
        .sync_reset    (sync_reset),
        .flush         (flush),
        .meta_stage2   (meta_stage2),
        .valid_stage2  (valid_stage2)
    );

    // Pipeline Stage 3: Generates the final reset output
    reset_output_pipeline_stage3 u_reset_output_pipeline_stage3 (
        .clock         (clock),
        .meta_in       (meta_stage2),
        .valid_in      (valid_stage2),
        .sync_reset    (sync_reset),
        .flush         (flush),
        .reset_out     (reset_out),
        .valid_out     (valid_out)
    );

endmodule

// ---------------------------------------------------------------------------
// Pipeline Stage 1: Asynchronous reset synchronization with valid
// ---------------------------------------------------------------------------
module async_reset_sync_stage1 (
    input  wire clock,
    input  wire async_reset,
    input  wire sync_reset,
    input  wire flush,
    input  wire start,
    output reg  meta_stage1,
    output reg  valid_stage1
);
    always @(posedge clock) begin
        if (sync_reset || flush) begin
            meta_stage1  <= 1'b1;
            valid_stage1 <= 1'b0;
        end else if (start) begin
            meta_stage1  <= async_reset;
            valid_stage1 <= 1'b1;
        end else begin
            meta_stage1  <= meta_stage1;
            valid_stage1 <= valid_stage1;
        end
    end
endmodule

// ---------------------------------------------------------------------------
// Pipeline Stage 2: Register meta output and propagate valid signal
// ---------------------------------------------------------------------------
module reset_pipeline_stage2 (
    input  wire clock,
    input  wire meta_in,
    input  wire valid_in,
    input  wire sync_reset,
    input  wire flush,
    output reg  meta_stage2,
    output reg  valid_stage2
);
    always @(posedge clock) begin
        if (sync_reset || flush) begin
            meta_stage2  <= 1'b1;
            valid_stage2 <= 1'b0;
        end else begin
            meta_stage2  <= meta_in;
            valid_stage2 <= valid_in;
        end
    end
endmodule

// ---------------------------------------------------------------------------
// Pipeline Stage 3: Generates the final reset output and valid
// ---------------------------------------------------------------------------
module reset_output_pipeline_stage3 (
    input  wire clock,
    input  wire meta_in,
    input  wire valid_in,
    input  wire sync_reset,
    input  wire flush,
    output reg  reset_out,
    output reg  valid_out
);
    always @(posedge clock) begin
        if (sync_reset || flush) begin
            reset_out <= 1'b1;
            valid_out <= 1'b0;
        end else begin
            reset_out <= meta_in;
            valid_out <= valid_in;
        end
    end
endmodule