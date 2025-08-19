//SystemVerilog
module usb_line_state_detector(
    input wire clk,
    input wire rst_n,
    input wire dp,
    input wire dm,
    output reg [1:0] line_state_out,
    output reg j_state_out,
    output reg k_state_out,
    output reg se0_state_out,
    output reg se1_state_out,
    output reg reset_detected_out
);
    localparam J_STATE = 2'b01, K_STATE = 2'b10, SE0 = 2'b00, SE1 = 2'b11;
    
    // Pipeline stage 1 - Input sampling
    reg [1:0] line_state_stage1;
    reg [1:0] prev_state_stage1;
    reg [7:0] reset_counter_stage1;
    
    // Pipeline stage 2 - State decoding
    reg [1:0] line_state_stage2;
    reg j_state_stage2, k_state_stage2, se0_state_stage2, se1_state_stage2;
    reg [7:0] reset_counter_stage2;
    reg [1:0] prev_state_stage2;
    
    // Pipeline stage 3 - Counter logic preparation
    reg [7:0] reset_counter_stage3;
    reg se0_state_stage3;
    reg counter_en_stage3;
    reg [7:0] p_stage3, g_stage3;
    
    // Pipeline stage 4 - Carry lookahead stage 1
    reg [7:0] reset_counter_stage4;
    reg se0_state_stage4;
    reg counter_en_stage4;
    reg [8:0] c_stage4_partial1; // First part of carry calculation
    reg [7:0] p_stage4, g_stage4;
    
    // Pipeline stage 5 - Carry lookahead stage 2
    reg [7:0] reset_counter_stage5;
    reg se0_state_stage5;
    reg [8:0] c_stage5;
    reg [7:0] p_stage5;
    
    // Pipeline stage 6 - Counter final and reset detection
    reg [7:0] next_counter_stage6;
    reg reset_detect_condition_stage6;
    reg se0_state_stage6;
    
    // Pipeline stage 7 - Output stage
    reg [1:0] line_state_stage7;
    reg j_state_stage7, k_state_stage7, se0_state_stage7, se1_state_stage7;
    reg reset_detected_stage7;
    reg [7:0] reset_counter_stage7;
    
    // Pipeline stage 1 - Input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_state_stage1 <= J_STATE;
            prev_state_stage1 <= J_STATE;
            reset_counter_stage1 <= 8'd0;
        end else begin
            line_state_stage1 <= {dp, dm};
            prev_state_stage1 <= line_state_stage1;
            reset_counter_stage1 <= (line_state_stage1 == SE0) ? reset_counter_stage7 : 8'd0;
        end
    end
    
    // Pipeline stage 2 - State decoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_state_stage2 <= J_STATE;
            j_state_stage2 <= 1'b0;
            k_state_stage2 <= 1'b0;
            se0_state_stage2 <= 1'b0;
            se1_state_stage2 <= 1'b0;
            reset_counter_stage2 <= 8'd0;
            prev_state_stage2 <= J_STATE;
        end else begin
            line_state_stage2 <= line_state_stage1;
            prev_state_stage2 <= prev_state_stage1;
            reset_counter_stage2 <= reset_counter_stage1;
            
            // Decode line states
            j_state_stage2 <= (line_state_stage1 == J_STATE);
            k_state_stage2 <= (line_state_stage1 == K_STATE);
            se0_state_stage2 <= (line_state_stage1 == SE0);
            se1_state_stage2 <= (line_state_stage1 == SE1);
        end
    end
    
    // Pipeline stage 3 - Counter logic preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_counter_stage3 <= 8'd0;
            se0_state_stage3 <= 1'b0;
            counter_en_stage3 <= 1'b0;
            p_stage3 <= 8'b0;
            g_stage3 <= 8'b0;
        end else begin
            reset_counter_stage3 <= reset_counter_stage2;
            se0_state_stage3 <= se0_state_stage2;
            counter_en_stage3 <= se0_state_stage2 && (reset_counter_stage2 < 8'd255);
            
            // Generate and propagate signals
            p_stage3 <= reset_counter_stage2;
            g_stage3 <= 8'b0;  // All zeros for increment by 1
        end
    end
    
    // Pipeline stage 4 - Carry lookahead stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_counter_stage4 <= 8'd0;
            se0_state_stage4 <= 1'b0;
            counter_en_stage4 <= 1'b0;
            c_stage4_partial1 <= 9'b0;
            p_stage4 <= 8'b0;
            g_stage4 <= 8'b0;
        end else begin
            reset_counter_stage4 <= reset_counter_stage3;
            se0_state_stage4 <= se0_state_stage3;
            counter_en_stage4 <= counter_en_stage3;
            p_stage4 <= p_stage3;
            g_stage4 <= g_stage3;
            
            // First part of carry calculations
            c_stage4_partial1[0] <= 1'b1;  // Initial carry-in is 1 for adding 1
            c_stage4_partial1[1] <= g_stage3[0] | (p_stage3[0] & 1'b1);
            c_stage4_partial1[2] <= g_stage3[1] | (p_stage3[1] & g_stage3[0]) | (p_stage3[1] & p_stage3[0] & 1'b1);
            c_stage4_partial1[3] <= g_stage3[2] | (p_stage3[2] & g_stage3[1]) | (p_stage3[2] & p_stage3[1] & g_stage3[0]) | 
                                   (p_stage3[2] & p_stage3[1] & p_stage3[0] & 1'b1);
        end
    end
    
    // Pipeline stage 5 - Carry lookahead stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_counter_stage5 <= 8'd0;
            se0_state_stage5 <= 1'b0;
            c_stage5 <= 9'b0;
            p_stage5 <= 8'b0;
        end else begin
            reset_counter_stage5 <= reset_counter_stage4;
            se0_state_stage5 <= se0_state_stage4;
            p_stage5 <= p_stage4;
            
            // Copy first part of carries
            c_stage5[3:0] <= c_stage4_partial1[3:0];
            
            // Complete carry calculations
            c_stage5[4] <= g_stage4[3] | (p_stage4[3] & g_stage4[2]) | (p_stage4[3] & p_stage4[2] & g_stage4[1]) | 
                          (p_stage4[3] & p_stage4[2] & p_stage4[1] & g_stage4[0]) | 
                          (p_stage4[3] & p_stage4[2] & p_stage4[1] & p_stage4[0] & 1'b1);
            c_stage5[5] <= g_stage4[4] | (p_stage4[4] & c_stage4_partial1[4]);
            c_stage5[6] <= g_stage4[5] | (p_stage4[5] & c_stage5[5]);
            c_stage5[7] <= g_stage4[6] | (p_stage4[6] & c_stage5[6]);
            c_stage5[8] <= g_stage4[7] | (p_stage4[7] & c_stage5[7]);
        end
    end
    
    // Pipeline stage 6 - Counter final and reset detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_counter_stage6 <= 8'd0;
            reset_detect_condition_stage6 <= 1'b0;
            se0_state_stage6 <= 1'b0;
        end else begin
            se0_state_stage6 <= se0_state_stage5;
            
            // Calculate sum using XOR
            next_counter_stage6 <= p_stage5 ^ c_stage5[7:0];
            
            // Reset detection condition
            reset_detect_condition_stage6 <= (reset_counter_stage5 > 8'd120);
        end
    end
    
    // Pipeline stage 7 - Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_state_stage7 <= J_STATE;
            j_state_stage7 <= 1'b0;
            k_state_stage7 <= 1'b0;
            se0_state_stage7 <= 1'b0;
            se1_state_stage7 <= 1'b0;
            reset_detected_stage7 <= 1'b0;
            reset_counter_stage7 <= 8'd0;
            
            line_state_out <= J_STATE;
            j_state_out <= 1'b0;
            k_state_out <= 1'b0;
            se0_state_out <= 1'b0;
            se1_state_out <= 1'b0;
            reset_detected_out <= 1'b0;
        end else begin
            // Pass through signals from stage 2
            line_state_stage7 <= line_state_stage2;
            j_state_stage7 <= j_state_stage2;
            k_state_stage7 <= k_state_stage2;
            se0_state_stage7 <= se0_state_stage6;
            se1_state_stage7 <= se1_state_stage2;
            
            // Handle reset detection and counter
            reset_detected_stage7 <= se0_state_stage6 && reset_detect_condition_stage6;
            
            // Update reset counter based on calculation
            reset_counter_stage7 <= se0_state_stage6 ? 
                                   (counter_en_stage4 ? next_counter_stage6 : reset_counter_stage5) : 
                                   8'd0;
            
            // Final output registers
            line_state_out <= line_state_stage7;
            j_state_out <= j_state_stage7;
            k_state_out <= k_state_stage7;
            se0_state_out <= se0_state_stage7;
            se1_state_out <= se1_state_stage7;
            reset_detected_out <= reset_detected_stage7;
        end
    end
endmodule