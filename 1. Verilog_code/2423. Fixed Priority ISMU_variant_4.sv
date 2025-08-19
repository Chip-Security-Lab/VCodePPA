//SystemVerilog
module priority_fixed_ismu #(parameter INT_COUNT = 16)(
    input clk, reset,
    input [INT_COUNT-1:0] int_src,
    input [INT_COUNT-1:0] int_enable,
    output reg [3:0] priority_num,
    output reg int_active
);
    // Pipeline stage 1: Compute masked interrupts and first-level priority detection
    reg [INT_COUNT-1:0] masked_int_stage1;
    reg [7:0] group_int_detected_stage1; // 8 groups detection signals
    
    // Pipeline stage 2: Group-level priority encoding
    reg [2:0] group_priority_stage2;
    reg group_has_int_stage2;
    reg [7:0] group_int_detected_stage2;
    
    // Pipeline stage 3: Fine-grained priority encoding
    reg [3:0] priority_value_stage3;
    reg has_interrupt_stage3;
    
    // Pipeline stage 1 logic
    always @(posedge clk) begin
        if (reset) begin
            masked_int_stage1 <= {INT_COUNT{1'b0}};
            group_int_detected_stage1 <= 8'b0;
        end else begin
            masked_int_stage1 <= int_src & int_enable;
            
            // Detect interrupts by groups to reduce path depth
            group_int_detected_stage1[0] <= |(int_src[1:0] & int_enable[1:0]);
            group_int_detected_stage1[1] <= |(int_src[3:2] & int_enable[3:2]);
            group_int_detected_stage1[2] <= |(int_src[5:4] & int_enable[5:4]);
            group_int_detected_stage1[3] <= |(int_src[7:6] & int_enable[7:6]);
            group_int_detected_stage1[4] <= |(int_src[9:8] & int_enable[9:8]);
            group_int_detected_stage1[5] <= |(int_src[11:10] & int_enable[11:10]);
            group_int_detected_stage1[6] <= |(int_src[13:12] & int_enable[13:12]);
            group_int_detected_stage1[7] <= |(int_src[15:14] & int_enable[15:14]);
        end
    end
    
    // Pipeline stage 2 logic
    always @(posedge clk) begin
        if (reset) begin
            group_priority_stage2 <= 3'b0;
            group_has_int_stage2 <= 1'b0;
            group_int_detected_stage2 <= 8'b0;
        end else begin
            group_int_detected_stage2 <= group_int_detected_stage1;
            
            // Group-level priority encoding
            if (group_int_detected_stage1[0]) begin
                group_priority_stage2 <= 3'd0;
                group_has_int_stage2 <= 1'b1;
            end else if (group_int_detected_stage1[1]) begin
                group_priority_stage2 <= 3'd1;
                group_has_int_stage2 <= 1'b1;
            end else if (group_int_detected_stage1[2]) begin
                group_priority_stage2 <= 3'd2;
                group_has_int_stage2 <= 1'b1;
            end else if (group_int_detected_stage1[3]) begin
                group_priority_stage2 <= 3'd3;
                group_has_int_stage2 <= 1'b1;
            end else if (group_int_detected_stage1[4]) begin
                group_priority_stage2 <= 3'd4;
                group_has_int_stage2 <= 1'b1;
            end else if (group_int_detected_stage1[5]) begin
                group_priority_stage2 <= 3'd5;
                group_has_int_stage2 <= 1'b1;
            end else if (group_int_detected_stage1[6]) begin
                group_priority_stage2 <= 3'd6;
                group_has_int_stage2 <= 1'b1;
            end else if (group_int_detected_stage1[7]) begin
                group_priority_stage2 <= 3'd7;
                group_has_int_stage2 <= 1'b1;
            end else begin
                group_priority_stage2 <= 3'd0;
                group_has_int_stage2 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 3 logic
    always @(posedge clk) begin
        if (reset) begin
            priority_value_stage3 <= 4'h0;
            has_interrupt_stage3 <= 1'b0;
        end else begin
            has_interrupt_stage3 <= group_has_int_stage2;
            
            // Fine-grained priority encoding based on group priority and masked interrupts
            case (group_priority_stage2)
                3'd0: begin
                    if (masked_int_stage1[0])
                        priority_value_stage3 <= 4'h0;
                    else
                        priority_value_stage3 <= 4'h1;
                end
                3'd1: begin
                    if (masked_int_stage1[2])
                        priority_value_stage3 <= 4'h2;
                    else
                        priority_value_stage3 <= 4'h3;
                end
                3'd2: begin
                    if (masked_int_stage1[4])
                        priority_value_stage3 <= 4'h4;
                    else
                        priority_value_stage3 <= 4'h5;
                end
                3'd3: begin
                    if (masked_int_stage1[6])
                        priority_value_stage3 <= 4'h6;
                    else
                        priority_value_stage3 <= 4'h7;
                end
                3'd4: begin
                    if (masked_int_stage1[8])
                        priority_value_stage3 <= 4'h8;
                    else
                        priority_value_stage3 <= 4'h9;
                end
                3'd5: begin
                    if (masked_int_stage1[10])
                        priority_value_stage3 <= 4'ha;
                    else
                        priority_value_stage3 <= 4'hb;
                end
                3'd6: begin
                    if (masked_int_stage1[12])
                        priority_value_stage3 <= 4'hc;
                    else
                        priority_value_stage3 <= 4'hd;
                end
                3'd7: begin
                    if (masked_int_stage1[14])
                        priority_value_stage3 <= 4'he;
                    else
                        priority_value_stage3 <= 4'hf;
                end
                default: priority_value_stage3 <= 4'h0;
            endcase
        end
    end
    
    // Output register update (final pipeline stage)
    always @(posedge clk) begin
        if (reset) begin
            priority_num <= 4'h0;
            int_active <= 1'b0;
        end else begin
            priority_num <= priority_value_stage3;
            int_active <= has_interrupt_stage3;
        end
    end
endmodule