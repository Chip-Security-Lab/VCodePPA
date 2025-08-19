//SystemVerilog
module dual_clock_reset_detector(
    input  wire clk_a,
    input  wire clk_b,
    input  wire rst_src_a,
    input  wire rst_src_b,
    output reg  reset_detected_a,
    output reg  reset_detected_b
);

// Pipeline registers and valid signals for clk_a domain
reg        sync_b_to_a_stage1;
reg        sync_b_to_a_stage2;
reg        sync_b_to_a_stage3;
reg        sync_b_to_a_stage4;
reg        reset_b_in_a_stage1;
reg        reset_b_in_a_stage2;
reg        reset_b_in_a_stage3;
reg        valid_b_to_a_stage1;
reg        valid_b_to_a_stage2;
reg        valid_b_to_a_stage3;
reg        valid_b_to_a_stage4;
reg        valid_b_to_a_stage5;

// Pipeline registers and valid signals for clk_b domain
reg        sync_a_to_b_stage1;
reg        sync_a_to_b_stage2;
reg        sync_a_to_b_stage3;
reg        sync_a_to_b_stage4;
reg        reset_a_in_b_stage1;
reg        reset_a_in_b_stage2;
reg        reset_a_in_b_stage3;
reg        valid_a_to_b_stage1;
reg        valid_a_to_b_stage2;
reg        valid_a_to_b_stage3;
reg        valid_a_to_b_stage4;
reg        valid_a_to_b_stage5;

// Flush logic (optional, can be tied to reset or other conditions)
wire flush_a = 1'b0;
wire flush_b = 1'b0;

// Clock domain A pipeline
always @(posedge clk_a) begin
    if (flush_a) begin
        sync_b_to_a_stage1    <= 1'b0;
        sync_b_to_a_stage2    <= 1'b0;
        sync_b_to_a_stage3    <= 1'b0;
        sync_b_to_a_stage4    <= 1'b0;
        reset_b_in_a_stage1   <= 1'b0;
        reset_b_in_a_stage2   <= 1'b0;
        reset_b_in_a_stage3   <= 1'b0;
        valid_b_to_a_stage1   <= 1'b0;
        valid_b_to_a_stage2   <= 1'b0;
        valid_b_to_a_stage3   <= 1'b0;
        valid_b_to_a_stage4   <= 1'b0;
        valid_b_to_a_stage5   <= 1'b0;
        reset_detected_a      <= 1'b0;
    end else begin
        // Stage 1: Capture rst_src_b
        sync_b_to_a_stage1    <= rst_src_b;
        valid_b_to_a_stage1   <= 1'b1;

        // Stage 2: Synchronize rst_src_b
        sync_b_to_a_stage2    <= sync_b_to_a_stage1;
        valid_b_to_a_stage2   <= valid_b_to_a_stage1;

        // Stage 3: Synchronize rst_src_b
        sync_b_to_a_stage3    <= sync_b_to_a_stage2;
        valid_b_to_a_stage3   <= valid_b_to_a_stage2;

        // Stage 4: Synchronize rst_src_b
        sync_b_to_a_stage4    <= sync_b_to_a_stage3;
        valid_b_to_a_stage4   <= valid_b_to_a_stage3;

        // Stage 5: Edge detect - first register
        reset_b_in_a_stage1   <= sync_b_to_a_stage4;
        valid_b_to_a_stage5   <= valid_b_to_a_stage4;

        // Stage 6: Edge detect - second register
        reset_b_in_a_stage2   <= reset_b_in_a_stage1;
        reset_b_in_a_stage3   <= reset_b_in_a_stage2;

        // Output logic
        if (valid_b_to_a_stage5) begin
            reset_detected_a  <= rst_src_a | reset_b_in_a_stage3;
        end else begin
            reset_detected_a  <= rst_src_a;
        end
    end
end

// Clock domain B pipeline
always @(posedge clk_b) begin
    if (flush_b) begin
        sync_a_to_b_stage1    <= 1'b0;
        sync_a_to_b_stage2    <= 1'b0;
        sync_a_to_b_stage3    <= 1'b0;
        sync_a_to_b_stage4    <= 1'b0;
        reset_a_in_b_stage1   <= 1'b0;
        reset_a_in_b_stage2   <= 1'b0;
        reset_a_in_b_stage3   <= 1'b0;
        valid_a_to_b_stage1   <= 1'b0;
        valid_a_to_b_stage2   <= 1'b0;
        valid_a_to_b_stage3   <= 1'b0;
        valid_a_to_b_stage4   <= 1'b0;
        valid_a_to_b_stage5   <= 1'b0;
        reset_detected_b      <= 1'b0;
    end else begin
        // Stage 1: Capture rst_src_a
        sync_a_to_b_stage1    <= rst_src_a;
        valid_a_to_b_stage1   <= 1'b1;

        // Stage 2: Synchronize rst_src_a
        sync_a_to_b_stage2    <= sync_a_to_b_stage1;
        valid_a_to_b_stage2   <= valid_a_to_b_stage1;

        // Stage 3: Synchronize rst_src_a
        sync_a_to_b_stage3    <= sync_a_to_b_stage2;
        valid_a_to_b_stage3   <= valid_a_to_b_stage2;

        // Stage 4: Synchronize rst_src_a
        sync_a_to_b_stage4    <= sync_a_to_b_stage3;
        valid_a_to_b_stage4   <= valid_a_to_b_stage3;

        // Stage 5: Edge detect - first register
        reset_a_in_b_stage1   <= sync_a_to_b_stage4;
        valid_a_to_b_stage5   <= valid_a_to_b_stage4;

        // Stage 6: Edge detect - second register
        reset_a_in_b_stage2   <= reset_a_in_b_stage1;
        reset_a_in_b_stage3   <= reset_a_in_b_stage2;

        // Output logic
        if (valid_a_to_b_stage5) begin
            reset_detected_b  <= rst_src_b | reset_a_in_b_stage3;
        end else begin
            reset_detected_b  <= rst_src_b;
        end
    end
end

endmodule