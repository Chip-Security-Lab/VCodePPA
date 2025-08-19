//SystemVerilog
// Top-level module: Dual clock domain reset detector pipeline
module dual_clock_reset_detector_pipeline(
    input  wire clk_a,
    input  wire clk_b,
    input  wire rst_src_a,
    input  wire rst_src_b,
    output wire reset_detected_a,
    output wire reset_detected_b
);

    // --- Clock domain A logic ---
    wire        sync_rst_b_to_a;
    wire        reset_detected_a_int;

    // Synchronizer for rst_src_b into clk_a domain
    reset_synchronizer #(
        .SYNC_STAGES(2)
    ) u_rst_b_to_a_sync (
        .clk        (clk_a),
        .async_in   (rst_src_b),
        .sync_out   (sync_rst_b_to_a)
    );

    // Reset detection pipeline in clk_a domain
    reset_detect_pipeline u_reset_detect_a (
        .clk                (clk_a),
        .local_rst_src      (rst_src_a),
        .remote_rst_sync    (sync_rst_b_to_a),
        .reset_detected     (reset_detected_a_int)
    );

    assign reset_detected_a = reset_detected_a_int;

    // --- Clock domain B logic ---
    wire        sync_rst_a_to_b;
    wire        reset_detected_b_int;

    // Synchronizer for rst_src_a into clk_b domain
    reset_synchronizer #(
        .SYNC_STAGES(2)
    ) u_rst_a_to_b_sync (
        .clk        (clk_b),
        .async_in   (rst_src_a),
        .sync_out   (sync_rst_a_to_b)
    );

    // Reset detection pipeline in clk_b domain
    reset_detect_pipeline u_reset_detect_b (
        .clk                (clk_b),
        .local_rst_src      (rst_src_b),
        .remote_rst_sync    (sync_rst_a_to_b),
        .reset_detected     (reset_detected_b_int)
    );

    assign reset_detected_b = reset_detected_b_int;

endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_synchronizer
// Purpose  : Multi-stage synchronizer for safe transfer of async signal to clk domain
// -----------------------------------------------------------------------------
module reset_synchronizer #(
    parameter SYNC_STAGES = 2
)(
    input  wire clk,
    input  wire async_in,
    output wire sync_out
);
    reg [SYNC_STAGES-1:0] sync_chain;

    integer i;
    always @(posedge clk) begin
        sync_chain[0] <= async_in;
        for (i = 1; i < SYNC_STAGES; i = i + 1)
            sync_chain[i] <= sync_chain[i-1];
    end

    assign sync_out = sync_chain[SYNC_STAGES-1];
endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_detect_pipeline
// Purpose  : Pipeline to detect reset event from local and synchronized remote
//            reset requests, with 4-stage pipeline and valid control
// -----------------------------------------------------------------------------
module reset_detect_pipeline(
    input  wire clk,
    input  wire local_rst_src,
    input  wire remote_rst_sync,
    output reg  reset_detected
);
    // Pipeline registers
    reg        local_rst_stage1, local_rst_stage2;
    reg        remote_rst_stage1, remote_rst_stage2;
    reg        reset_detect_stage1, reset_detect_stage2;
    reg        valid_stage1, valid_stage2, valid_stage3;

    always @(posedge clk) begin
        // Stage 1: Capture remote and local reset requests
        remote_rst_stage1     <= remote_rst_sync;
        local_rst_stage1      <= local_rst_src;
        valid_stage1          <= 1'b1;

        // Stage 2: Hold and propagate
        remote_rst_stage2     <= remote_rst_stage1;
        local_rst_stage2      <= local_rst_stage1;
        valid_stage2          <= valid_stage1;

        // Stage 3: Detect reset condition
        reset_detect_stage1   <= local_rst_stage2 | remote_rst_stage2;
        valid_stage3          <= valid_stage2;

        // Stage 4: Output register
        reset_detect_stage2   <= reset_detect_stage1;

        if (valid_stage3)
            reset_detected    <= reset_detect_stage2;
        else
            reset_detected    <= 1'b0;
    end
endmodule