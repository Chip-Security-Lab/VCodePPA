//SystemVerilog
module dynamic_divider (
    input clock, reset_b, load,
    input [7:0] divide_value,
    output reg divided_clock
);
    // Stage 1: Input and control registers
    reg [7:0] divider_reg_stage1;
    reg [7:0] counter_stage1;
    reg valid_stage1;
    reg divided_clock_stage1;
    
    // Stage 2: Comparison and computation registers
    reg [7:0] divider_reg_stage2;
    reg [7:0] counter_stage2;
    reg valid_stage2;
    reg counter_reset_stage2;
    reg toggle_clock_stage2;
    reg divided_clock_stage2;
    
    // Stage 3: Update registers
    reg [7:0] counter_stage3;
    reg valid_stage3;
    
    // Kogge-Stone adder signals
    wire [7:0] ks_sum;
    wire [7:0] p_stage1, g_stage1;
    wire [7:0] p_stage2, g_stage2;
    wire [7:0] p_stage3, g_stage3;
    
    // Stage 1: Input and control logic
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            divider_reg_stage1 <= 8'h1;
            counter_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
            divided_clock_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if (load)
                divider_reg_stage1 <= divide_value;
                
            // Forward result from stage 3 back to stage 1 for counter
            if (valid_stage3)
                counter_stage1 <= counter_stage3;
                
            // Forward divided clock value
            if (valid_stage2 && toggle_clock_stage2)
                divided_clock_stage1 <= ~divided_clock_stage1;
        end
    end
    
    // Stage 2: Comparison and computation
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            divider_reg_stage2 <= 8'h1;
            counter_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            counter_reset_stage2 <= 1'b0;
            toggle_clock_stage2 <= 1'b0;
            divided_clock_stage2 <= 1'b0;
        end else begin
            // Pass values from stage 1 to stage 2
            divider_reg_stage2 <= divider_reg_stage1;
            counter_stage2 <= counter_stage1;
            valid_stage2 <= valid_stage1;
            divided_clock_stage2 <= divided_clock_stage1;
            
            // Comparison logic
            if (valid_stage1) begin
                if (counter_stage1 >= divider_reg_stage1 - 1) begin
                    counter_reset_stage2 <= 1'b1;
                    toggle_clock_stage2 <= 1'b1;
                end else begin
                    counter_reset_stage2 <= 1'b0;
                    toggle_clock_stage2 <= 1'b0;
                end
            end else begin
                counter_reset_stage2 <= 1'b0;
                toggle_clock_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Counter update using Kogge-Stone adder
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            counter_stage3 <= 8'h0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            // Update counter based on stage 2 result
            if (valid_stage2) begin
                if (counter_reset_stage2)
                    counter_stage3 <= 8'h0;
                else
                    counter_stage3 <= ks_sum; // Use Kogge-Stone adder output
            end
        end
    end
    
    // Output assignment
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            divided_clock <= 1'b0;
        end else begin
            divided_clock <= divided_clock_stage1;
        end
    end
    
    // Kogge-Stone 8-bit adder implementation
    // Generate propagate and generate signals (first stage)
    assign p_stage1 = counter_stage2 ^ 8'h01;    // P = A XOR B
    assign g_stage1 = counter_stage2 & 8'h01;    // G = A AND B
    
    // Stage 2 - compute prefix operation for distance 1
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[0] = g_stage1[0];
    
    assign p_stage2[7:1] = p_stage1[7:1] & p_stage1[6:0];
    assign g_stage2[7:1] = g_stage1[7:1] | (p_stage1[7:1] & g_stage1[6:0]);
    
    // Stage 3 - compute prefix operation for distance 2
    assign p_stage3[1:0] = p_stage2[1:0];
    assign g_stage3[1:0] = g_stage2[1:0];
    
    assign p_stage3[7:2] = p_stage2[7:2] & p_stage2[5:0];
    assign g_stage3[7:2] = g_stage2[7:2] | (p_stage2[7:2] & g_stage2[5:0]);
    
    // Final stage - compute sum
    assign ks_sum[0] = p_stage1[0] ^ 1'b0;           // First bit has no carry-in
    assign ks_sum[1] = p_stage1[1] ^ g_stage3[0];
    assign ks_sum[2] = p_stage1[2] ^ g_stage3[1];
    assign ks_sum[3] = p_stage1[3] ^ g_stage3[2];
    assign ks_sum[4] = p_stage1[4] ^ g_stage3[3];
    assign ks_sum[5] = p_stage1[5] ^ g_stage3[4];
    assign ks_sum[6] = p_stage1[6] ^ g_stage3[5];
    assign ks_sum[7] = p_stage1[7] ^ g_stage3[6];
endmodule