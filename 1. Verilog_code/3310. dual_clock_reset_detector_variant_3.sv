//SystemVerilog
module dual_clock_reset_detector(
    input  wire clk_a,
    input  wire clk_b,
    input  wire rst_src_a,
    input  wire rst_src_b,
    output reg  reset_detected_a,
    output reg  reset_detected_b
);

// Pipeline depth increased to 3 for both synchronizers

// Synchronizer for rst_src_b into clk_a domain
reg sync_b_to_a_stage1 = 1'b0;
reg sync_b_to_a_stage2 = 1'b0;
reg sync_b_to_a_stage3 = 1'b0;
reg reset_b_in_a_stage1 = 1'b0;
reg reset_b_in_a_stage2 = 1'b0;

// Synchronizer for rst_src_a into clk_b domain
reg sync_a_to_b_stage1 = 1'b0;
reg sync_a_to_b_stage2 = 1'b0;
reg sync_a_to_b_stage3 = 1'b0;
reg reset_a_in_b_stage1 = 1'b0;
reg reset_a_in_b_stage2 = 1'b0;

// Pipeline for reset_detected_a
reg reset_detected_a_stage1 = 1'b0;
reg reset_detected_a_stage2 = 1'b0;

// Pipeline for reset_detected_b
reg reset_detected_b_stage1 = 1'b0;
reg reset_detected_b_stage2 = 1'b0;

// Clock domain A pipeline
always @(posedge clk_a) begin
    // Synchronizing rst_src_b to clk_a domain with 3 FFs
    sync_b_to_a_stage1 <= rst_src_b;
    sync_b_to_a_stage2 <= sync_b_to_a_stage1;
    sync_b_to_a_stage3 <= sync_b_to_a_stage2;

    // Pipeline for reset_b_in_a
    reset_b_in_a_stage1 <= sync_b_to_a_stage3;
    reset_b_in_a_stage2 <= reset_b_in_a_stage1;

    // Pipeline for reset_detected_a
    reset_detected_a_stage1 <= rst_src_a | reset_b_in_a_stage2;
    reset_detected_a_stage2 <= reset_detected_a_stage1;
    reset_detected_a <= reset_detected_a_stage2;
end

// Clock domain B pipeline
always @(posedge clk_b) begin
    // Synchronizing rst_src_a to clk_b domain with 3 FFs
    sync_a_to_b_stage1 <= rst_src_a;
    sync_a_to_b_stage2 <= sync_a_to_b_stage1;
    sync_a_to_b_stage3 <= sync_a_to_b_stage2;

    // Pipeline for reset_a_in_b
    reset_a_in_b_stage1 <= sync_a_to_b_stage3;
    reset_a_in_b_stage2 <= reset_a_in_b_stage1;

    // Pipeline for reset_detected_b
    reset_detected_b_stage1 <= rst_src_b | reset_a_in_b_stage2;
    reset_detected_b_stage2 <= reset_detected_b_stage1;
    reset_detected_b <= reset_detected_b_stage2;
end

endmodule