//SystemVerilog
module ResetDetectorAsync (
    input  wire clk,
    input  wire rst_n,
    output wire reset_detected
);

    // Pipeline stage 1: Detect reset and initiate pipeline
    reg reset_detected_stage1;
    reg valid_stage1;

    // Pipeline stage 2: Final register for output (merged original stage 2 and 3)
    reg reset_detected_stage2;
    reg valid_stage2;

    // Stage 1: Detect reset and initiate pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected_stage1 <= 1'b1;
            valid_stage1          <= 1'b1;
        end else begin
            reset_detected_stage1 <= 1'b0;
            valid_stage1          <= 1'b1;
        end
    end

    // Stage 2: Register the outputs from stage 1 (merged)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected_stage2 <= 1'b0;
            valid_stage2          <= 1'b0;
        end else begin
            reset_detected_stage2 <= reset_detected_stage1;
            valid_stage2          <= valid_stage1;
        end
    end

    assign reset_detected = valid_stage2 ? reset_detected_stage2 : 1'b0;

endmodule