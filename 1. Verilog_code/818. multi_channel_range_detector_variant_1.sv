//SystemVerilog
module multi_channel_range_detector(
    input wire clk,
    input wire [7:0] data_ch1, data_ch2,
    input wire [7:0] lower_bound, upper_bound,
    output reg ch1_in_range, ch2_in_range
);
    wire ch1_result, ch2_result;
    
    optimized_range_check range_check(
        .data1(data_ch1),
        .data2(data_ch2),
        .low(lower_bound),
        .high(upper_bound),
        .result1(ch1_result),
        .result2(ch2_result)
    );
    
    always @(posedge clk) begin
        ch1_in_range <= ch1_result;
        ch2_in_range <= ch2_result;
    end
endmodule

module optimized_range_check(
    input wire [7:0] data1, data2,
    input wire [7:0] low, high,
    output wire result1, result2
);
    // 使用超出范围的条件，然后取反，减少逻辑层级
    wire [8:0] low_minus_1 = {1'b0, low} - 9'd1;
    wire [8:0] high_plus_1 = {1'b0, high} + 9'd1;
    
    wire out_of_range1 = ({1'b0, data1} <= low_minus_1) || ({1'b0, data1} >= high_plus_1);
    wire out_of_range2 = ({1'b0, data2} <= low_minus_1) || ({1'b0, data2} >= high_plus_1);
    
    // 取反以获取在范围内的结果
    assign result1 = ~out_of_range1;
    assign result2 = ~out_of_range2;
endmodule