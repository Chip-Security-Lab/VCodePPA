//SystemVerilog
module range_detector_indicators(
    input wire [11:0] input_value,
    input wire [11:0] min_threshold, max_threshold,
    output reg in_range,
    output reg below_range,
    output reg above_range
);

    // 使用时序逻辑优化比较链
    always @(*) begin
        below_range = 1'b0;
        above_range = 1'b0;
        in_range = 1'b0;
        
        if (input_value < min_threshold) begin
            below_range = 1'b1;
        end
        else if (input_value > max_threshold) begin
            above_range = 1'b1;
        end
        else begin
            in_range = 1'b1;
        end
    end
    
endmodule