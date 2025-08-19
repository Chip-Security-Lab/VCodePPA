module pipelined_range_detector(
    input wire clock, reset,
    input wire [23:0] data,
    input wire [23:0] min_range, max_range,
    output reg valid_range
);
    reg stage1_above_min, stage1_below_max;
    reg stage2_in_range;
    
    always @(posedge clock) begin
        if (reset) begin
            stage1_above_min <= 1'b0; stage1_below_max <= 1'b0;
            stage2_in_range <= 1'b0; valid_range <= 1'b0;
        end else begin
            stage1_above_min <= (data >= min_range);
            stage1_below_max <= (data <= max_range);
            stage2_in_range <= stage1_above_min && stage1_below_max;
            valid_range <= stage2_in_range;
        end
    end
endmodule