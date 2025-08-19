//SystemVerilog
module Sync_NAND(
    input clk,
    input [7:0] d1,
    input [7:0] d2,
    output reg [7:0] q
);

    // Pipeline Stage 1: Register inputs
    reg [7:0] d1_stage1, d2_stage1;
    always @(posedge clk) begin
        d1_stage1 <= d1;
        d2_stage1 <= d2;
    end

    // Pipeline Stage 2: Split AND operation into two pipeline stages for higher frequency
    reg [3:0] d1_stage2_upper, d1_stage2_lower;
    reg [3:0] d2_stage2_upper, d2_stage2_lower;
    always @(posedge clk) begin
        d1_stage2_upper <= d1_stage1[7:4];
        d1_stage2_lower <= d1_stage1[3:0];
        d2_stage2_upper <= d2_stage1[7:4];
        d2_stage2_lower <= d2_stage1[3:0];
    end

    // Pipeline Stage 3: Perform AND operation on lower and upper nibbles separately
    reg [3:0] and_lower_stage3, and_upper_stage3;
    always @(posedge clk) begin
        and_lower_stage3 <= d1_stage2_lower & d2_stage2_lower;
        and_upper_stage3 <= d1_stage2_upper & d2_stage2_upper;
    end

    // Pipeline Stage 4: Combine and register the full AND result
    reg [7:0] and_result_stage4;
    always @(posedge clk) begin
        and_result_stage4 <= {and_upper_stage3, and_lower_stage3};
    end

    // Pipeline Stage 5: Perform NOT operation and output register
    always @(posedge clk) begin
        q <= ~and_result_stage4;
    end

endmodule