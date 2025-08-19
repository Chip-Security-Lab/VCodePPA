//SystemVerilog
module ResetCounterWithThreshold #(
    parameter THRESHOLD = 10
) (
    input  wire clk,
    input  wire rst_n,
    output wire reset_detected
);

    // Stage 1: Sample reset and initialize counter
    reg rst_n_sync_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rst_n_sync_stage1 <= 1'b0;
        else
            rst_n_sync_stage1 <= 1'b1;
    end

    // Stage 2: Counter increment logic (register moved forward)
    reg [3:0] counter_stage2_d;
    reg [3:0] counter_stage2_q;
    always @(*) begin
        if (!rst_n_sync_stage1)
            counter_stage2_d = 4'b0;
        else if (counter_stage2_q < THRESHOLD)
            counter_stage2_d = counter_stage2_q + 1'b1;
        else
            counter_stage2_d = counter_stage2_q;
    end

    always @(posedge clk or negedge rst_n_sync_stage1) begin
        if (!rst_n_sync_stage1)
            counter_stage2_q <= 4'b0;
        else
            counter_stage2_q <= counter_stage2_d;
    end

    // Stage 3: Output pipeline register moved before combinational logic
    reg reset_detected_stage3_q;
    reg reset_detected_stage3_d;
    always @(*) begin
        if (!rst_n_sync_stage1)
            reset_detected_stage3_d = 1'b0;
        else
            reset_detected_stage3_d = (counter_stage2_q >= THRESHOLD);
    end

    always @(posedge clk or negedge rst_n_sync_stage1) begin
        if (!rst_n_sync_stage1)
            reset_detected_stage3_q <= 1'b0;
        else
            reset_detected_stage3_q <= reset_detected_stage3_d;
    end

    assign reset_detected = reset_detected_stage3_q;

endmodule