//SystemVerilog
module pipelined_range_detector(
    input wire clock, reset,
    input wire [23:0] data,
    input wire [23:0] min_range, max_range,
    input wire data_valid,
    output reg data_ready,
    output reg valid_range,
    output reg valid_out
);
    // Pipeline control signals
    reg data_valid_stage1, data_valid_stage2, data_valid_stage3;
    
    // Pipeline stage 1 - Comparison operations
    reg [23:0] data_stage1;
    reg [23:0] min_range_stage1, max_range_stage1;
    reg stage1_above_min, stage1_below_max;
    
    // Pipeline stage 2 - Logical operation
    reg stage2_in_range;
    
    // Pipeline stage 3 - Output stage
    
    always @(posedge clock) begin
        if (reset) begin
            // Reset pipeline control signals
            data_valid_stage1 <= 1'b0;
            data_valid_stage2 <= 1'b0;
            data_valid_stage3 <= 1'b0;
            valid_out <= 1'b0;
            
            // Reset data registers
            data_stage1 <= 24'd0;
            min_range_stage1 <= 24'd0;
            max_range_stage1 <= 24'd0;
            
            // Reset computation registers
            stage1_above_min <= 1'b0;
            stage1_below_max <= 1'b0;
            stage2_in_range <= 1'b0;
            valid_range <= 1'b0;
            
            // Set ready for new data
            data_ready <= 1'b1;
        end else begin
            // Pipeline Stage 1: Register inputs and perform comparisons
            if (data_ready && data_valid) begin
                data_stage1 <= data;
                min_range_stage1 <= min_range;
                max_range_stage1 <= max_range;
                stage1_above_min <= (data >= min_range);
                stage1_below_max <= (data <= max_range);
                data_valid_stage1 <= 1'b1;
            end else if (data_valid_stage2 || !data_valid_stage1) begin
                data_valid_stage1 <= 1'b0;
            end
            
            // Pipeline Stage 2: Combine comparison results
            data_valid_stage2 <= data_valid_stage1;
            if (data_valid_stage1) begin
                stage2_in_range <= stage1_above_min && stage1_below_max;
            end
            
            // Pipeline Stage 3: Final output
            data_valid_stage3 <= data_valid_stage2;
            if (data_valid_stage2) begin
                valid_range <= stage2_in_range;
            end
            
            // Output valid signal
            valid_out <= data_valid_stage3;
            
            // Ready for new data when pipeline is not full or moving
            data_ready <= !data_valid_stage1 || data_valid_stage2;
        end
    end
endmodule