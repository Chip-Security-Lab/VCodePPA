//SystemVerilog
module pipelined_range_detector(
    input wire clock, reset,
    input wire [23:0] data,
    input wire [23:0] min_range, max_range,
    output reg valid_range
);
    reg stage1_above_min, stage1_below_max;
    reg stage2_above_min, stage2_below_max;
    reg stage3_in_range;
    
    always @(posedge clock)
        begin
            // Stage 1: Compare with min_range
            stage1_above_min <= reset ? 1'b0 : (data >= min_range);
            
            // Stage 2: Compare with max_range and pipeline min comparison
            stage2_above_min <= reset ? 1'b0 : stage1_above_min;
            stage2_below_max <= reset ? 1'b0 : (data <= max_range);
            
            // Stage 3: Combine comparisons
            stage3_in_range <= reset ? 1'b0 : (stage2_above_min && stage2_below_max);
            
            // Stage 4: Output
            valid_range <= reset ? 1'b0 : stage3_in_range;
        end
endmodule