//SystemVerilog
// Top-level module: ResetDetectorSync
module ResetDetectorSync (
    input wire clk,
    input wire rst_n,
    output wire reset_detected
);

    // Internal signal for reset detection
    wire reset_detected_internal;

    // Instance: Reset Detection Core
    ResetDetectionCore u_reset_detection_core (
        .clk(clk),
        .rst_n(rst_n),
        .reset_detected(reset_detected_internal)
    );

    // Output assignment
    assign reset_detected = reset_detected_internal;

endmodule

// -----------------------------------------------------------------------------
// Module: ResetDetectionCore
// Function: Handles reset_detected signal generation based on rst_n input
// Inputs:
//   - clk: Clock signal
//   - rst_n: Active-low asynchronous reset
// Outputs:
//   - reset_detected: Indicates reset event (asserted when rst_n is low)
// -----------------------------------------------------------------------------
module ResetDetectionCore (
    input wire clk,
    input wire rst_n,
    output reg reset_detected
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected <= 1'b1;
        end else begin
            reset_detected <= 1'b0;
        end
    end
endmodule