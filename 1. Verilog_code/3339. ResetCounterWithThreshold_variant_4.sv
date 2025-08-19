//SystemVerilog
module ResetCounterWithThreshold #(
    parameter THRESHOLD = 10
) (
    input wire clk,
    input wire rst_n,
    output wire reset_detected
);

    // Stage 1: Counter Pipeline Register
    reg [3:0] counter_stage1;
    // Stage 2: Counter Compare Register
    reg counter_compare_stage2;
    // Stage 3: Reset Flag Register
    reg reset_flag_stage3;

    // Stage 1: Counter increment logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= 4'd0;
        end else if (!reset_flag_stage3) begin
            counter_stage1 <= counter_stage1 + 1'b1;
        end
    end

    // Stage 2: Threshold comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_compare_stage2 <= 1'b0;
        end else if (!reset_flag_stage3) begin
            counter_compare_stage2 <= (counter_stage1 == (THRESHOLD - 1));
        end else begin
            counter_compare_stage2 <= 1'b0;
        end
    end

    // Stage 3: Reset flag logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_flag_stage3 <= 1'b0;
        end else if (!reset_flag_stage3 && counter_compare_stage2) begin
            reset_flag_stage3 <= 1'b1;
        end
    end

    assign reset_detected = reset_flag_stage3;

endmodule