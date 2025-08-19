//SystemVerilog
module ResetEdgeDetector (
    input  wire clk,
    input  wire rst_n,
    output reg  reset_edge_detected
);

    // Stage 1: Sample input
    reg rst_n_stage1;
    reg valid_stage1;

    // Stage 2: Hold previous value (delayed input)
    reg rst_n_stage2;
    reg valid_stage2;

    // Stage 3: Edge detection logic
    reg reset_edge_detected_stage3;
    reg valid_stage3;

    // Pipeline registers and valid chain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_stage1              <= 1'b0;
            valid_stage1              <= 1'b0;
            rst_n_stage2              <= 1'b0;
            valid_stage2              <= 1'b0;
            reset_edge_detected_stage3<= 1'b0;
            valid_stage3              <= 1'b0;
            reset_edge_detected       <= 1'b0;
        end else begin
            // Stage 1: sample input
            rst_n_stage1   <= rst_n;
            valid_stage1   <= 1'b1;

            // Stage 2: delay input for edge detection
            rst_n_stage2   <= rst_n_stage1;
            valid_stage2   <= valid_stage1;

            // Stage 3: detect edge
            reset_edge_detected_stage3 <= rst_n_stage2 & ~rst_n_stage1;
            valid_stage3               <= valid_stage2;

            // Output stage: update output only when valid
            if (valid_stage3)
                reset_edge_detected <= reset_edge_detected_stage3;
            else
                reset_edge_detected <= 1'b0;
        end
    end

endmodule