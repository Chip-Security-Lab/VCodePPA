//SystemVerilog
module sync_reset_ring_counter(
    input wire clock,
    input wire reset, // Active-high reset
    input wire enable, // Input enable signal for pipeline control
    output reg [3:0] out,
    output reg out_valid // Output valid signal
);
    // Pre-compute rotation directly from input
    wire [3:0] rotated_data = {out[2:0], out[3]};
    
    // Pipeline stage registers with reduced logic in critical path
    reg [3:0] stage1_data;
    reg stage1_valid;
    reg [3:0] stage2_data;
    reg stage2_valid;
    
    // Reset buffering - moved to non-critical paths
    reg reset_buf1, reset_buf2, reset_buf3;
    
    // Reset buffering logic with sequential update
    always @(posedge clock) begin
        reset_buf1 <= reset;
        reset_buf2 <= reset_buf1;
        reset_buf3 <= reset_buf2;
    end
    
    // Stage 1: Register input after pre-computation
    always @(posedge clock) begin
        if (reset_buf1) begin
            stage1_data <= 4'b0001;
            stage1_valid <= 1'b0;
        end
        else begin
            // Only update data when enabled
            if (enable) begin
                stage1_data <= rotated_data;
                stage1_valid <= 1'b1;
            end
            else begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // Stage 2: Intermediate processing with balanced path delay
    always @(posedge clock) begin
        if (reset_buf2) begin
            stage2_data <= 4'b0001;
            stage2_valid <= 1'b0;
        end
        else begin
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Output stage: Final result with optimized timing
    always @(posedge clock) begin
        if (reset_buf3) begin
            out <= 4'b0001;
            out_valid <= 1'b0;
        end
        else begin
            out <= stage2_data;
            out_valid <= stage2_valid;
        end
    end
endmodule