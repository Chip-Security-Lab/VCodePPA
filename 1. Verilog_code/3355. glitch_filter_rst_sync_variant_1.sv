//SystemVerilog
module glitch_filter_rst_sync (
    input  wire clk,
    input  wire async_rst_n,
    output wire filtered_rst_n
);
    // Stage 1: Input sampling and shift register
    reg [3:0] shift_reg_stage1;
    reg       valid_stage1;
    
    // Stage 2: Pattern detection signals
    reg [3:0] shift_reg_stage2;
    reg       valid_stage2;
    reg       pattern_ones;
    reg       pattern_zeros;
    
    // Early pattern detection signals (for path balancing)
    wire      early_ones_detect;
    wire      early_zeros_detect;
    
    // Stage 3: Filtering logic
    reg       filtered_stage3;
    reg       valid_stage3;
    
    // Early pattern detection logic to reduce critical path
    // Pre-compute pattern detection conditions
    assign early_ones_detect = (shift_reg_stage1 == 4'b1111);
    assign early_zeros_detect = (shift_reg_stage1 == 4'b0000);
    
    // Stage 1: Input sampling and shift register
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
        end
        else begin
            // Use concatenation for better timing
            shift_reg_stage1 <= {shift_reg_stage1[2:0], 1'b1};
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Pattern detection
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
            pattern_ones <= 1'b0;
            pattern_zeros <= 1'b0;
        end
        else begin
            shift_reg_stage2 <= shift_reg_stage1;
            valid_stage2 <= valid_stage1;
            
            // Use pre-computed pattern detection results
            pattern_ones <= early_ones_detect;
            pattern_zeros <= early_zeros_detect;
        end
    end
    
    // Stage 3: Filtering logic - use simplified control path
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            filtered_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            valid_stage3 <= valid_stage2;
            
            // Simplified priority logic with single if statement
            // This reduces the sequential logic depth
            if (pattern_ones | (filtered_stage3 & ~pattern_zeros))
                filtered_stage3 <= 1'b1;
            else
                filtered_stage3 <= 1'b0;
        end
    end
    
    // Output assignment
    assign filtered_rst_n = filtered_stage3;
    
endmodule