//SystemVerilog
module serial_bit_comparator(
    input clk,
    input reset,
    input bit_a,         // Serial data input A
    input bit_b,         // Serial data input B
    input start_compare, // Start the comparison process
    input bit_valid,     // Indicates valid bits are present
    output reg match,    // Final result: 1 if all bits matched
    output reg busy      // Comparator is processing
);

    // FSM states
    localparam IDLE = 2'b00;
    localparam COMPARING = 2'b01;
    localparam COMPLETE = 2'b10;
    
    // Pipeline registers - increased from 2 to 4 stages
    reg [1:0] state_stage1, state_stage2, state_stage3, state_stage4;
    reg bit_a_stage1, bit_a_stage2;
    reg bit_b_stage1, bit_b_stage2;
    reg bit_valid_stage1, bit_valid_stage2;
    reg match_stage1, match_stage2, match_stage3, match_stage4;
    reg busy_stage1, busy_stage2, busy_stage3, busy_stage4;
    reg start_compare_stage1, start_compare_stage2;
    reg bit_equal_stage2;
    
    // Next state logic
    reg [1:0] next_state;
    
    // Stage 1: Input sampling
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= IDLE;
            bit_a_stage1 <= 1'b0;
            bit_b_stage1 <= 1'b0;
            bit_valid_stage1 <= 1'b0;
            match_stage1 <= 1'b0;
            busy_stage1 <= 1'b0;
            start_compare_stage1 <= 1'b0;
        end else begin
            bit_a_stage1 <= bit_a;
            bit_b_stage1 <= bit_b;
            bit_valid_stage1 <= bit_valid;
            start_compare_stage1 <= start_compare;
            state_stage1 <= next_state;
            
            case (state_stage1)
                IDLE: begin
                    if (start_compare) begin
                        match_stage1 <= 1'b1;
                        busy_stage1 <= 1'b1;
                    end
                end
                
                COMPARING: begin
                    // Only update match in this stage, actual comparison in next stage
                end
                
                COMPLETE: begin
                    busy_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // Stage 2: Bit comparison
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage2 <= IDLE;
            bit_a_stage2 <= 1'b0;
            bit_b_stage2 <= 1'b0;
            bit_valid_stage2 <= 1'b0;
            match_stage2 <= 1'b0;
            busy_stage2 <= 1'b0;
            start_compare_stage2 <= 1'b0;
            bit_equal_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            bit_a_stage2 <= bit_a_stage1;
            bit_b_stage2 <= bit_b_stage1;
            bit_valid_stage2 <= bit_valid_stage1;
            match_stage2 <= match_stage1;
            busy_stage2 <= busy_stage1;
            start_compare_stage2 <= start_compare_stage1;
            
            // Perform bit comparison
            bit_equal_stage2 <= (bit_a_stage1 == bit_b_stage1);
            
            // Update match based on comparison result
            if (state_stage1 == COMPARING && bit_valid_stage1 && !bit_equal_stage2) begin
                match_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: State transition
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage3 <= IDLE;
            match_stage3 <= 1'b0;
            busy_stage3 <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            match_stage3 <= match_stage2;
            busy_stage3 <= busy_stage2;
        end
    end
    
    // Stage 4: Final processing and output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage4 <= IDLE;
            match_stage4 <= 1'b0;
            busy_stage4 <= 1'b0;
        end else begin
            state_stage4 <= state_stage3;
            match_stage4 <= match_stage3;
            busy_stage4 <= busy_stage3;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state_stage1;
        
        case (state_stage1)
            IDLE: begin
                if (start_compare_stage1)
                    next_state = COMPARING;
            end
            
            COMPARING: begin
                if (!bit_valid_stage1)
                    next_state = COMPLETE;
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output assignments
    assign match = match_stage4;
    assign busy = busy_stage4;
    
endmodule