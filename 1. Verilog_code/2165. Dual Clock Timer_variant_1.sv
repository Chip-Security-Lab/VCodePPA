//SystemVerilog
module dual_clock_timer (
    input wire clk_fast, clk_slow, reset_n,
    input wire [15:0] target,
    output reg tick_out
);
    // Fast clock domain - increased pipeline depth
    reg [15:0] counter_fast_stage1;
    reg [15:0] counter_fast_stage2;
    reg [15:0] target_stage1;
    reg [15:0] target_stage2;
    
    // Carry skip adder signals
    reg [15:0] sum_stage1;
    wire [16:0] carry;
    wire [3:0] block_propagate;
    wire [15:0] propagate;
    
    // Generate propagate signals for each bit
    assign propagate = counter_fast_stage1 ^ 16'h0001;
    
    // Group propagate signals for 4-bit blocks
    assign block_propagate[0] = &propagate[3:0];
    assign block_propagate[1] = &propagate[7:4];
    assign block_propagate[2] = &propagate[11:8];
    assign block_propagate[3] = &propagate[15:12];
    
    // Initial carry
    assign carry[0] = 1'b0;
    
    // Calculate carries for each block with skip logic
    assign carry[4] = block_propagate[0] ? carry[0] : 
                     (propagate[3] & carry[3] | propagate[3] & propagate[2] & carry[2] |
                      propagate[3] & propagate[2] & propagate[1] & carry[1] | 
                      propagate[3] & propagate[2] & propagate[1] & propagate[0] & carry[0]);
                      
    assign carry[8] = block_propagate[1] ? carry[4] : 
                     (propagate[7] & carry[7] | propagate[7] & propagate[6] & carry[6] |
                      propagate[7] & propagate[6] & propagate[5] & carry[5] | 
                      propagate[7] & propagate[6] & propagate[5] & propagate[4] & carry[4]);
                      
    assign carry[12] = block_propagate[2] ? carry[8] : 
                      (propagate[11] & carry[11] | propagate[11] & propagate[10] & carry[10] |
                       propagate[11] & propagate[10] & propagate[9] & carry[9] | 
                       propagate[11] & propagate[10] & propagate[9] & propagate[8] & carry[8]);
                       
    assign carry[16] = block_propagate[3] ? carry[12] : 
                      (propagate[15] & carry[15] | propagate[15] & propagate[14] & carry[14] |
                       propagate[15] & propagate[14] & propagate[13] & carry[13] | 
                       propagate[15] & propagate[14] & propagate[13] & propagate[12] & carry[12]);
    
    // Calculate intermediate carries (could be optimized in actual hardware)
    generate
        genvar i;
        for (i = 0; i < 16; i = i + 1) begin : gen_carries
            if (i % 4 != 3) begin
                assign carry[i+1] = (counter_fast_stage1[i] & 1'b1) | (propagate[i] & carry[i]);
            end
        end
    endgenerate
    
    // Sum computation
    wire [15:0] incr_result;
    assign incr_result = counter_fast_stage1 ^ {15'b0, carry[0]} ^ {carry[16:1]};
    
    // Counter logic pipeline stage 1
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            counter_fast_stage1 <= 16'h0000;
            target_stage1 <= 16'h0000;
        end else begin
            counter_fast_stage1 <= incr_result;
            target_stage1 <= target;
        end
    end
    
    // Counter logic pipeline stage 2
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            counter_fast_stage2 <= 16'h0000;
            target_stage2 <= 16'h0000;
        end else begin
            counter_fast_stage2 <= counter_fast_stage1;
            target_stage2 <= target_stage1;
        end
    end

    // Comparison pipeline stages
    reg compare_result_stage1;
    reg compare_result_stage2;
    reg match_detected_pre;
    reg match_detected;
    
    // Comparison stage 1 - split comparison logic
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            compare_result_stage1 <= 1'b0;
        end else begin
            compare_result_stage1 <= (counter_fast_stage2[7:0] == target_stage2[7:0]);
        end
    end
    
    // Comparison stage 2 - complete the comparison
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            compare_result_stage2 <= 1'b0;
        end else begin
            compare_result_stage2 <= compare_result_stage1 && 
                                    (counter_fast_stage2[15:8] == target_stage2[15:8]);
        end
    end
    
    // Pre-match detection stage
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            match_detected_pre <= 1'b0;
        end else begin
            match_detected_pre <= compare_result_stage2;
        end
    end

    // Final match detection stage
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            match_detected <= 1'b0;
        end else begin
            match_detected <= match_detected_pre;
        end
    end

    // Slow clock domain - increased sync stages for better metastability handling
    reg sync_match_stage1;
    reg sync_match_stage2;
    reg sync_match_stage3;
    reg prev_sync_match_stage1;
    reg prev_sync_match_stage2;
    
    // Synchronizer stage 1
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_match_stage1 <= 1'b0;
        end else begin
            sync_match_stage1 <= match_detected;
        end
    end
    
    // Synchronizer stage 2
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_match_stage2 <= 1'b0;
        end else begin
            sync_match_stage2 <= sync_match_stage1;
        end
    end
    
    // Synchronizer stage 3
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_match_stage3 <= 1'b0;
        end else begin
            sync_match_stage3 <= sync_match_stage2;
        end
    end
    
    // Edge detection pipeline stage 1
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            prev_sync_match_stage1 <= 1'b0;
        end else begin
            prev_sync_match_stage1 <= sync_match_stage3;
        end
    end
    
    // Edge detection pipeline stage 2
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            prev_sync_match_stage2 <= 1'b0;
        end else begin
            prev_sync_match_stage2 <= prev_sync_match_stage1;
        end
    end

    // Output generation with pipelined edge detection logic
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            tick_out <= 1'b0;
        end else begin
            tick_out <= sync_match_stage3 & ~prev_sync_match_stage2;
        end
    end
endmodule