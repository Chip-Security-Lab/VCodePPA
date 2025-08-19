module multi_channel_range_detector(
    input wire clk,
    input wire [7:0] data_ch1, data_ch2,
    input wire [7:0] lower_bound, upper_bound,
    output reg ch1_in_range, ch2_in_range
);
    wire ch1_result, ch2_result;
    
    comparator comp1(.data(data_ch1), .low(lower_bound), .high(upper_bound), .result(ch1_result));
    comparator comp2(.data(data_ch2), .low(lower_bound), .high(upper_bound), .result(ch2_result));
    
    always @(posedge clk) begin
        ch1_in_range <= ch1_result;
        ch2_in_range <= ch2_result;
    end
endmodule

// 添加缺失的comparator模块
module comparator(
    input wire [7:0] data,
    input wire [7:0] low,
    input wire [7:0] high,
    output wire result
);
    assign result = (data >= low) && (data <= high);
endmodule