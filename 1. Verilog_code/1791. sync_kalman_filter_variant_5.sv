//SystemVerilog
module sync_kalman_filter #(
    parameter DATA_W = 16,
    parameter FRAC_BITS = 8
)(
    input clk, reset,
    input [DATA_W-1:0] measurement,
    input [DATA_W-1:0] process_noise,
    input [DATA_W-1:0] measurement_noise,
    output reg [DATA_W-1:0] estimate
);

    // Stage 1 registers
    reg [DATA_W-1:0] measurement_stage1;
    reg [DATA_W-1:0] process_noise_stage1;
    reg [DATA_W-1:0] measurement_noise_stage1;
    reg [DATA_W-1:0] prediction_stage1;
    reg [DATA_W-1:0] error_stage1;
    reg valid_stage1;

    // Stage 2 registers
    reg [DATA_W-1:0] prediction_stage2;
    reg [DATA_W-1:0] error_stage2;
    reg [DATA_W-1:0] innovation_stage2;
    reg valid_stage2;

    // Stage 3 registers
    reg [DATA_W-1:0] gain_stage3;
    reg [DATA_W-1:0] prediction_stage3;
    reg [DATA_W-1:0] error_stage3;
    reg [DATA_W-1:0] innovation_stage3;
    reg valid_stage3;

    // Stage 4 registers
    reg [DATA_W-1:0] estimate_stage4;
    reg [DATA_W-1:0] error_stage4;
    reg valid_stage4;

    // Stage 1: Input registration and prediction
    always @(posedge clk) begin
        if (reset) begin
            measurement_stage1 <= 0;
            process_noise_stage1 <= 0;
            measurement_noise_stage1 <= 0;
            prediction_stage1 <= 0;
            error_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            measurement_stage1 <= measurement;
            process_noise_stage1 <= process_noise;
            measurement_noise_stage1 <= measurement_noise;
            prediction_stage1 <= estimate_stage4;
            error_stage1 <= error_stage4 + process_noise_stage1;
            valid_stage1 <= 1;
        end
    end

    // Stage 2: Innovation calculation
    always @(posedge clk) begin
        if (reset) begin
            prediction_stage2 <= 0;
            error_stage2 <= 0;
            innovation_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            prediction_stage2 <= prediction_stage1;
            error_stage2 <= error_stage1;
            innovation_stage2 <= measurement_stage1 - prediction_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Gain calculation
    always @(posedge clk) begin
        if (reset) begin
            gain_stage3 <= 0;
            prediction_stage3 <= 0;
            error_stage3 <= 0;
            innovation_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            gain_stage3 <= (error_stage2 << FRAC_BITS) / (error_stage2 + measurement_noise_stage1);
            prediction_stage3 <= prediction_stage2;
            error_stage3 <= error_stage2;
            innovation_stage3 <= innovation_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Final update
    always @(posedge clk) begin
        if (reset) begin
            estimate_stage4 <= 0;
            error_stage4 <= 0;
            valid_stage4 <= 0;
        end else begin
            estimate_stage4 <= prediction_stage3 + ((gain_stage3 * innovation_stage3) >> FRAC_BITS);
            error_stage4 <= ((1 << FRAC_BITS) - gain_stage3) * error_stage3 >> FRAC_BITS;
            valid_stage4 <= valid_stage3;
        end
    end

    // Output assignment
    always @(posedge clk) begin
        if (reset) begin
            estimate <= 0;
        end else begin
            estimate <= estimate_stage4;
        end
    end

endmodule