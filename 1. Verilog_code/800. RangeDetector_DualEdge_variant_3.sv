//SystemVerilog
module RangeDetector_DualEdge #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg rise_detected,
    output reg fall_detected
);

// Stage 1: Comparison pipeline
reg comparison_result_stage1;
reg [WIDTH-1:0] data_in_stage1, threshold_stage1;

// Stage 2: Previous state capture and edge detection preparation
reg comparison_result_stage2;
reg prev_state_stage2;

// Stage 3: Edge detection
reg rise_detected_stage3;
reg fall_detected_stage3;

// Stage 1: Data capture and comparison
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        comparison_result_stage1 <= 0;
        data_in_stage1 <= 0;
        threshold_stage1 <= 0;
    end
    else begin
        data_in_stage1 <= data_in;
        threshold_stage1 <= threshold;
        comparison_result_stage1 <= (data_in >= threshold);
    end
end

// Stage 2: Store previous state and pass comparison result
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        comparison_result_stage2 <= 0;
        prev_state_stage2 <= 0;
    end
    else begin
        comparison_result_stage2 <= comparison_result_stage1;
        prev_state_stage2 <= comparison_result_stage2;
    end
end

// Stage 3: Edge detection logic
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rise_detected_stage3 <= 0;
        fall_detected_stage3 <= 0;
    end
    else begin
        rise_detected_stage3 <= (!prev_state_stage2 && comparison_result_stage2);
        fall_detected_stage3 <= (prev_state_stage2 && !comparison_result_stage2);
    end
end

// Final stage: Output registers
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rise_detected <= 0;
        fall_detected <= 0;
    end
    else begin
        rise_detected <= rise_detected_stage3;
        fall_detected <= fall_detected_stage3;
    end
end

endmodule