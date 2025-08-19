//SystemVerilog
module usb_clock_recovery(
    input wire dp_in,
    input wire dm_in,
    input wire ref_clk,
    input wire rst_n,
    output reg recovered_clk,
    output reg bit_locked
);
    // Pipeline stage registers
    // Stage 1: Input and XOR computation
    reg dp_stage1, dm_stage1;
    reg dp_dm_xor_stage1;
    reg valid_stage1;
    
    // Stage 2: Edge detection
    reg dp_dm_xor_stage2;
    reg [1:0] edge_history_stage2;
    reg valid_stage2;
    
    // Stage 3: Rising edge detection
    reg edge_detected_stage3;
    reg valid_stage3;
    
    // Stage 4: Period counting
    reg [7:0] period_count_stage4;
    reg edge_detected_stage4;
    reg valid_stage4;
    
    // Stage 5: Clock generation
    reg [7:0] clock_divider_stage5;
    reg clock_state_stage5;
    
    // Pipeline stage 1: Input registration and XOR computation
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_stage1 <= 1'b0;
            dm_stage1 <= 1'b0;
            dp_dm_xor_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            dp_stage1 <= dp_in;
            dm_stage1 <= dm_in;
            dp_dm_xor_stage1 <= dp_in ^ dm_in;
            valid_stage1 <= 1'b1;  // Always valid after reset
        end
    end
    
    // Pipeline stage 2: Edge detection history
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_dm_xor_stage2 <= 1'b0;
            edge_history_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            dp_dm_xor_stage2 <= dp_dm_xor_stage1;
            edge_history_stage2 <= {edge_history_stage2[0], dp_dm_xor_stage1};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Rising edge detection
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detected_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            // Detect rising edge (01 pattern)
            edge_detected_stage3 <= (edge_history_stage2 == 2'b01);
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline stage 4: Period counting
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            period_count_stage4 <= 8'd0;
            edge_detected_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else if (valid_stage3) begin
            edge_detected_stage4 <= edge_detected_stage3;
            
            if (edge_detected_stage3) begin
                period_count_stage4 <= 8'd0;  // Reset counter on edge
            end else if (period_count_stage4 < 8'd255) begin
                period_count_stage4 <= period_count_stage4 + 1'b1;
            end
            
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Pipeline stage 5: Clock recovery and lock detection
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_clk <= 1'b0;
            bit_locked <= 1'b0;
            clock_divider_stage5 <= 8'd0;
            clock_state_stage5 <= 1'b0;
        end else if (valid_stage4) begin
            // Update clock divider
            if (edge_detected_stage4) begin
                // If we see consistent timing between edges, we're locked
                if (period_count_stage4 > 8'd10 && period_count_stage4 < 8'd30) begin
                    bit_locked <= 1'b1;
                    clock_divider_stage5 <= period_count_stage4; // Use measured period
                end
            end
            
            // Generate recovered clock
            if (bit_locked) begin
                if (edge_detected_stage4) begin
                    clock_state_stage5 <= 1'b1;  // Start high on edge
                    recovered_clk <= 1'b1;
                end else if (clock_divider_stage5 > 8'd0) begin
                    // Toggle clock at half the measured period
                    if (period_count_stage4 >= {1'b0, clock_divider_stage5[7:1]}) begin
                        clock_state_stage5 <= ~clock_state_stage5;
                        recovered_clk <= ~clock_state_stage5;
                    end
                end
            end
            
            // Unlock detection - if no edges for too long
            if (period_count_stage4 > 8'd100) begin
                bit_locked <= 1'b0;
                recovered_clk <= 1'b0;
            end
        end
    end
endmodule