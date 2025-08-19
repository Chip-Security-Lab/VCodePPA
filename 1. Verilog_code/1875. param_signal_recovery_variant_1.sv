//SystemVerilog
module param_signal_recovery #(
    parameter SIGNAL_WIDTH = 12,
    parameter THRESHOLD = 2048,
    parameter NOISE_MARGIN = 256
)(
    input wire sample_clk,
    input wire rst_n,
    input wire [SIGNAL_WIDTH-1:0] input_signal,
    output reg [SIGNAL_WIDTH-1:0] recovered_signal,
    output reg valid_out
);

    // Stage 1: Input Register and Threshold Calculation
    reg [SIGNAL_WIDTH-1:0] input_signal_stage1;
    reg [SIGNAL_WIDTH-1:0] threshold_lower_stage1;
    reg [SIGNAL_WIDTH-1:0] threshold_upper_stage1;
    reg valid_stage1;

    // Stage 2: Comparison Logic
    reg [SIGNAL_WIDTH-1:0] input_signal_stage2;
    reg [SIGNAL_WIDTH-1:0] threshold_lower_stage2;
    reg [SIGNAL_WIDTH-1:0] threshold_upper_stage2;
    reg valid_stage2;

    // Stage 3: Signal Recovery
    reg [SIGNAL_WIDTH-1:0] input_signal_stage3;
    reg valid_stage3;

    // Stage 1 Logic
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            input_signal_stage1 <= 0;
            threshold_lower_stage1 <= 0;
            threshold_upper_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            input_signal_stage1 <= input_signal;
            threshold_lower_stage1 <= THRESHOLD - NOISE_MARGIN;
            threshold_upper_stage1 <= THRESHOLD + NOISE_MARGIN;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2 Logic
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            input_signal_stage2 <= 0;
            threshold_lower_stage2 <= 0;
            threshold_upper_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            input_signal_stage2 <= input_signal_stage1;
            threshold_lower_stage2 <= threshold_lower_stage1;
            threshold_upper_stage2 <= threshold_upper_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3 Logic
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            input_signal_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            input_signal_stage3 <= input_signal_stage2;
            valid_stage3 <= valid_stage2 && 
                          (input_signal_stage2 > threshold_lower_stage2) && 
                          (input_signal_stage2 < threshold_upper_stage2);
        end
    end

    // Output Stage
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_signal <= 0;
            valid_out <= 0;
        end else begin
            recovered_signal <= valid_stage3 ? input_signal_stage3 : recovered_signal;
            valid_out <= valid_stage3;
        end
    end

endmodule