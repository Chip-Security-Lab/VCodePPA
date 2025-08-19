//SystemVerilog
module pipelined_rgb_to_ycbcr (
    input clk, rst_n,
    input [23:0] rgb_in,
    input rgb_valid,
    output reg rgb_ready,
    output reg [23:0] ycbcr_out,
    output reg ycbcr_valid,
    input ycbcr_ready
);
    // Stage 1 - Input registers
    reg [23:0] rgb_stage1;
    reg valid_stage1;
    
    // Stage 2 - RGB separation and pre-calculation
    reg [7:0] r_stage2, g_stage2, b_stage2;
    reg [7:0] r_inv_stage2, g_inv_stage2, b_inv_stage2; // Pre-invert values to reduce critical path
    reg [15:0] y_part1_stage2, cb_part1_stage2, cr_part1_stage2;
    reg valid_stage2;
    
    // Stage 3 - Parallel computations 
    reg [15:0] y_part2_stage3, cb_part2_stage3, cr_part2_stage3;
    reg [15:0] y_part3_stage3, cb_part3_stage3, cr_part3_stage3;
    reg valid_stage3;
    
    // Stage 4 - Balanced summation
    reg [15:0] y_sum_stage4, cb_sum_stage4, cr_sum_stage4;
    reg valid_stage4;
    
    // Stage 5 - Shift, offset and preliminary clamp
    reg [15:0] y_shifted_stage5, cb_shifted_stage5, cr_shifted_stage5;
    reg [8:0] y_prelim_stage5, cb_prelim_stage5, cr_prelim_stage5; // 9-bit for overflow detection
    reg valid_stage5;
    
    // Stage 6 - Final clamp and output preparation
    reg [7:0] y_stage6, cb_stage6, cr_stage6;
    reg valid_stage6;
    
    // Pipeline control signals - Optimized for better timing
    wire stage1_ready, stage2_ready, stage3_ready, stage4_ready, stage5_ready, stage6_ready;
    wire output_ready;
    
    // Constants for computation - Pre-defined to reduce logic depth
    localparam [7:0] Y_OFFSET = 8'd16;
    localparam [7:0] CBCR_OFFSET = 8'd128;
    
    // Optimized handshaking logic
    assign output_ready = !ycbcr_valid || ycbcr_ready;
    assign stage6_ready = !valid_stage6 || output_ready;
    assign stage5_ready = !valid_stage5 || stage6_ready;
    assign stage4_ready = !valid_stage4 || stage5_ready;
    assign stage3_ready = !valid_stage3 || stage4_ready;
    assign stage2_ready = !valid_stage2 || stage3_ready;
    assign stage1_ready = !valid_stage1 || stage2_ready;
    
    // Input ready signal - combinational logic
    always @(*) begin
        rgb_ready = stage1_ready;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            rgb_stage1 <= 24'h0;
            valid_stage1 <= 1'b0;
            
            r_stage2 <= 8'h0;
            g_stage2 <= 8'h0;
            b_stage2 <= 8'h0;
            r_inv_stage2 <= 8'h0;
            g_inv_stage2 <= 8'h0;
            b_inv_stage2 <= 8'h0;
            y_part1_stage2 <= 16'h0;
            cb_part1_stage2 <= 16'h0;
            cr_part1_stage2 <= 16'h0;
            valid_stage2 <= 1'b0;
            
            y_part2_stage3 <= 16'h0;
            cb_part2_stage3 <= 16'h0;
            cr_part2_stage3 <= 16'h0;
            y_part3_stage3 <= 16'h0;
            cb_part3_stage3 <= 16'h0;
            cr_part3_stage3 <= 16'h0;
            valid_stage3 <= 1'b0;
            
            y_sum_stage4 <= 16'h0;
            cb_sum_stage4 <= 16'h0;
            cr_sum_stage4 <= 16'h0;
            valid_stage4 <= 1'b0;
            
            y_shifted_stage5 <= 16'h0;
            cb_shifted_stage5 <= 16'h0;
            cr_shifted_stage5 <= 16'h0;
            y_prelim_stage5 <= 9'h0;
            cb_prelim_stage5 <= 9'h0;
            cr_prelim_stage5 <= 9'h0;
            valid_stage5 <= 1'b0;
            
            y_stage6 <= 8'h0;
            cb_stage6 <= 8'h0;
            cr_stage6 <= 8'h0;
            valid_stage6 <= 1'b0;
            
            ycbcr_out <= 24'h0;
            ycbcr_valid <= 1'b0;
        end else begin
            // Pipeline stage 1: Register inputs (with handshaking)
            if (rgb_valid && rgb_ready) begin
                rgb_stage1 <= rgb_in;
                valid_stage1 <= 1'b1;
            end else if (stage1_ready) begin
                valid_stage1 <= 1'b0;
            end
            
            // Pipeline stage 2: Separate RGB components, pre-compute inverted values and start multiplications
            if (valid_stage1 && stage2_ready) begin
                // Extract components
                r_stage2 <= rgb_stage1[23:16];
                g_stage2 <= rgb_stage1[15:8];
                b_stage2 <= rgb_stage1[7:0];
                
                // Pre-compute inverted values to reduce critical path in subsequent stages
                r_inv_stage2 <= ~rgb_stage1[23:16];
                g_inv_stage2 <= ~rgb_stage1[15:8];
                b_inv_stage2 <= ~rgb_stage1[7:0];
                
                // First part of multiplications - each component separately for better balancing
                y_part1_stage2 <= 16'd66 * rgb_stage1[23:16]; // R component for Y
                cb_part1_stage2 <= 16'd38; // Pre-multiply for Cb
                cr_part1_stage2 <= 16'd112 * rgb_stage1[23:16]; // R component for Cr
                
                valid_stage2 <= 1'b1;
            end else if (stage2_ready) begin
                valid_stage2 <= 1'b0;
            end
            
            // Pipeline stage 3: Parallel computation paths
            if (valid_stage2 && stage3_ready) begin
                // Split computations for Y
                y_part2_stage3 <= 16'd129 * g_stage2;
                y_part3_stage3 <= 16'd25 * b_stage2 + 16'd128; // Pre-add constant
                
                // Split computations for Cb - using pre-inverted values
                cb_part2_stage3 <= cb_part1_stage2 * r_inv_stage2;
                cb_part3_stage3 <= 16'd74 * g_inv_stage2 + 16'd112 * b_stage2 + 16'd128;
                
                // Split computations for Cr - using pre-inverted values
                cr_part2_stage3 <= 16'd94 * g_inv_stage2;
                cr_part3_stage3 <= 16'd18 * b_inv_stage2 + 16'd128;
                
                valid_stage3 <= 1'b1;
            end else if (stage3_ready) begin
                valid_stage3 <= 1'b0;
            end
            
            // Pipeline stage 4: Balanced summation
            if (valid_stage3 && stage4_ready) begin
                // Balanced addition trees
                y_sum_stage4 <= y_part1_stage2 + y_part2_stage3 + y_part3_stage3;
                cb_sum_stage4 <= cb_part2_stage3 + cb_part3_stage3;
                cr_sum_stage4 <= cr_part1_stage2 + cr_part2_stage3 + cr_part3_stage3;
                
                valid_stage4 <= 1'b1;
            end else if (stage4_ready) begin
                valid_stage4 <= 1'b0;
            end
            
            // Pipeline stage 5: Shift, offset and preliminary clamping
            if (valid_stage4 && stage5_ready) begin
                // Shift results
                y_shifted_stage5 <= y_sum_stage4 >> 8;
                cb_shifted_stage5 <= cb_sum_stage4 >> 8;
                cr_shifted_stage5 <= cr_sum_stage4 >> 8;
                
                // Add offset with preliminary clamp check (9-bit to detect overflow)
                y_prelim_stage5 <= (y_sum_stage4 >> 8) + Y_OFFSET;
                cb_prelim_stage5 <= (cb_sum_stage4 >> 8) + CBCR_OFFSET;
                cr_prelim_stage5 <= (cr_sum_stage4 >> 8) + CBCR_OFFSET;
                
                valid_stage5 <= 1'b1;
            end else if (stage5_ready) begin
                valid_stage5 <= 1'b0;
            end
            
            // Pipeline stage 6: Final clamp using preliminary computation
            if (valid_stage5 && stage6_ready) begin
                // Optimized clamping using the 9-bit preliminary values
                y_stage6 <= y_prelim_stage5[8] ? 8'hFF : (|y_prelim_stage5[8:7]) ? 8'h00 : y_prelim_stage5[7:0];
                cb_stage6 <= cb_prelim_stage5[8] ? 8'hFF : (|cb_prelim_stage5[8:7]) ? 8'h00 : cb_prelim_stage5[7:0];
                cr_stage6 <= cr_prelim_stage5[8] ? 8'hFF : (|cr_prelim_stage5[8:7]) ? 8'h00 : cr_prelim_stage5[7:0];
                
                valid_stage6 <= 1'b1;
            end else if (stage6_ready) begin
                valid_stage6 <= 1'b0;
            end
            
            // Output stage: Pack results (with handshaking)
            if (valid_stage6 && output_ready) begin
                ycbcr_out <= {y_stage6, cb_stage6, cr_stage6};
                ycbcr_valid <= 1'b1;
            end else if (ycbcr_ready) begin
                ycbcr_valid <= 1'b0;
            end
        end
    end
endmodule