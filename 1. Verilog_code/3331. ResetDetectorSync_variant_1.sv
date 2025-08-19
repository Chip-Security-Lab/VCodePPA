//SystemVerilog
// Top-level module: Hierarchical reset detector with input synchronizer
module ResetDetectorSync (
    input  wire clk,
    input  wire rst_n,
    output wire reset_detected
);

    wire rst_n_sync;

    // Synchronizer submodule instance: synchronizes the asynchronous reset input
    ResetSynchronizer u_reset_synchronizer (
        .clk        (clk),
        .async_rst_n(rst_n),
        .sync_rst_n (rst_n_sync)
    );

    // Detector submodule instance: detects reset deassertion
    ResetDetectLogic u_reset_detect_logic (
        .clk            (clk),
        .rst_n_sync     (rst_n_sync),
        .reset_detected (reset_detected)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: ResetSynchronizer
// Purpose  : Synchronizes asynchronous reset input to the local clock domain
//------------------------------------------------------------------------------
module ResetSynchronizer (
    input  wire clk,
    input  wire async_rst_n,
    output wire sync_rst_n
);
    reg rst_sync_ff1, rst_sync_ff2;

    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_sync_ff1 <= 1'b0;
            rst_sync_ff2 <= 1'b0;
        end else begin
            rst_sync_ff1 <= 1'b1;
            rst_sync_ff2 <= rst_sync_ff1;
        end
    end

    assign sync_rst_n = rst_sync_ff2;

endmodule

//------------------------------------------------------------------------------
// Submodule: ResetDetectLogic
// Purpose  : Detects when reset is asserted (active low) and generates pulse
//------------------------------------------------------------------------------
module ResetDetectLogic (
    input  wire clk,
    input  wire rst_n_sync,
    output reg  reset_detected
);
    always @(posedge clk) begin
        reset_detected <= (!rst_n_sync) ? 1'b1 : 1'b0;
    end
endmodule