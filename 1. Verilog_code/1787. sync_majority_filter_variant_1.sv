//SystemVerilog
module sync_majority_filter #(
    parameter WINDOW = 5,
    parameter W = WINDOW / 2 + 1  // Majority threshold
)(
    input clk, rst_n,
    input data_in,
    output reg data_out
);
    // Stage 1 registers
    reg [WINDOW-1:0] shift_reg_stage1;
    reg bit_leaving_stage1;
    
    // Stage 2 registers
    reg [WINDOW-1:0] shift_reg_stage2;
    reg [2:0] one_count_stage2;
    reg bit_leaving_stage2;
    reg data_in_stage2;
    
    // Stage 3 registers
    reg [2:0] one_count_stage3;
    reg data_in_stage3;
    
    // Stage 4 registers
    reg majority_flag_stage4;
    
    // Stage 1: Shift register and bit leaving computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 0;
            bit_leaving_stage1 <= 0;
        end else begin
            // Pre-compute bit leaving the window
            bit_leaving_stage1 <= shift_reg_stage1[WINDOW-1];
            
            // Shift in new data
            shift_reg_stage1 <= {shift_reg_stage1[WINDOW-2:0], data_in};
        end
    end
    
    // Stage 2: Data transfer and preparation for one_count update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 0;
            one_count_stage2 <= 0;
            bit_leaving_stage2 <= 0;
            data_in_stage2 <= 0;
        end else begin
            shift_reg_stage2 <= shift_reg_stage1;
            one_count_stage2 <= one_count_stage3; // Feedback from stage 3
            bit_leaving_stage2 <= bit_leaving_stage1;
            data_in_stage2 <= data_in;
        end
    end
    
    // Stage 3: One count update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_count_stage3 <= 0;
            data_in_stage3 <= 0;
        end else begin
            // Update one count based on bits entering/leaving window
            if (data_in_stage2 && !bit_leaving_stage2)
                one_count_stage3 <= one_count_stage2 + 1'b1;
            else if (!data_in_stage2 && bit_leaving_stage2)
                one_count_stage3 <= one_count_stage2 - 1'b1;
            else
                one_count_stage3 <= one_count_stage2;
                
            data_in_stage3 <= data_in_stage2;
        end
    end
    
    // Stage 4: Majority computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            majority_flag_stage4 <= 0;
            data_out <= 0;
        end else begin
            // Compute majority decision
            majority_flag_stage4 <= (one_count_stage3 >= (W-1)) || 
                                   ((one_count_stage3 == (W-2)) && data_in_stage3);
            
            // Register the decision
            data_out <= majority_flag_stage4;
        end
    end
endmodule