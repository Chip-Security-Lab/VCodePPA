//SystemVerilog
module ResetDetectorWithEnable_Pipelined (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    output wire reset_detected
);

    // Stage 1: Capture inputs and compute next state
    reg enable_stage1;
    reg rst_n_stage1;
    reg reset_detected_stage1;
    reg valid_stage1;

    // Stage 2: Register next state and valid
    reg reset_detected_stage2;
    reg valid_stage2;

    // Pipeline: Valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1           <= 1'b0;
            rst_n_stage1            <= 1'b0;
            reset_detected_stage1   <= 1'b1;
            valid_stage1            <= 1'b0;
        end else begin
            enable_stage1           <= enable;
            rst_n_stage1            <= rst_n;
            reset_detected_stage1   <= reset_detected_stage2;
            valid_stage1            <= 1'b1;
        end
    end

    // Stage 2: Logic and output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected_stage2   <= 1'b1;
            valid_stage2            <= 1'b0;
        end else if (valid_stage1) begin
            if (!rst_n_stage1) begin
                reset_detected_stage2 <= 1'b1;
            end else if (enable_stage1) begin
                reset_detected_stage2 <= 1'b0;
            end else begin
                reset_detected_stage2 <= reset_detected_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end

    assign reset_detected = reset_detected_stage2;

endmodule