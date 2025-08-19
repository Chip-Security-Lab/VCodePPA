//SystemVerilog
module edge_detect_sync_pipeline (
    input  wire        clkA,
    input  wire        clkB,
    input  wire        rst_n,
    input  wire        signal_in,
    output wire        pos_edge,
    output wire        neg_edge
);

    // Forward retimed synchronizer: move register after combinational logic
    // Synchronizer chain (classic 2-stage sync)
    reg        signal_sync_stage2;
    reg        signal_sync_stage3;

    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            signal_sync_stage2 <= 1'b0;
            signal_sync_stage3 <= 1'b0;
        end else begin
            signal_sync_stage2 <= signal_in;
            signal_sync_stage3 <= signal_sync_stage2;
        end
    end

    // Edge detection combinational logic
    wire posedge_detected;
    wire negedge_detected;

    assign posedge_detected = (signal_sync_stage3 == 1'b1) && (signal_sync_stage2 == 1'b0);
    assign negedge_detected = (signal_sync_stage3 == 1'b0) && (signal_sync_stage2 == 1'b1);

    // Moved edge detection registers after combinational logic
    reg pos_edge_stage4;
    reg neg_edge_stage4;

    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            pos_edge_stage4 <= 1'b0;
            neg_edge_stage4 <= 1'b0;
        end else begin
            pos_edge_stage4 <= posedge_detected;
            neg_edge_stage4 <= negedge_detected;
        end
    end

    // Valid chain for pipeline stages
    reg valid_stage2, valid_stage3, valid_stage4;
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            valid_stage2 <= 1'b1; // Always valid after reset deasserted
            valid_stage3 <= valid_stage2;
            valid_stage4 <= valid_stage3;
        end
    end

    // Output assignment with valid gating
    assign pos_edge = valid_stage4 ? pos_edge_stage4 : 1'b0;
    assign neg_edge = valid_stage4 ? neg_edge_stage4 : 1'b0;

endmodule