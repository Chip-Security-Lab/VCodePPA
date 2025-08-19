//SystemVerilog
module RangeDetector_DynamicTh #(
    parameter WIDTH = 8
)(
    input clk, wr_en,
    input [WIDTH-1:0] new_low,
    input [WIDTH-1:0] new_high,
    input [WIDTH-1:0] data_in,
    output reg out_flag
);
    // Threshold registers
    reg [WIDTH-1:0] current_low, current_high;
    
    // Pipeline stage 1 - Store input data and perform first comparison
    reg [WIDTH-1:0] data_stage1;
    reg low_compare_stage1;
    
    // Pipeline stage 2 - Perform second comparison
    reg high_compare_stage2;
    reg low_compare_stage2;
    
    // Update thresholds
    always @(posedge clk) begin
        if(wr_en) begin
            current_low <= new_low;
            current_high <= new_high;
        end
    end
    
    // Pipeline stage 1: Register inputs and perform first comparison
    always @(posedge clk) begin
        data_stage1 <= data_in;
        low_compare_stage1 <= (data_in >= current_low);
    end
    
    // Pipeline stage 2: Perform second comparison and forward first comparison
    always @(posedge clk) begin
        low_compare_stage2 <= low_compare_stage1;
        high_compare_stage2 <= (data_stage1 <= current_high);
    end
    
    // Final output stage: AND the results
    always @(posedge clk) begin
        out_flag <= low_compare_stage2 && high_compare_stage2;
    end
endmodule