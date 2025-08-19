module range_detector_active_low(
    input wire clock, reset,
    input wire [7:0] value,
    input wire [7:0] range_low, range_high,
    output reg range_valid_n
);
    wire comp_result_n;
    
    comparator_low comp1 (
        .in_value(value),
        .lower_lim(range_low),
        .upper_lim(range_high),
        .out_of_range(comp_result_n)
    );
    
    always @(posedge clock) begin
        if (reset) range_valid_n <= 1'b1;
        else range_valid_n <= comp_result_n;
    end
endmodule

// 添加缺失的comparator_low模块
module comparator_low(
    input wire [7:0] in_value,
    input wire [7:0] lower_lim,
    input wire [7:0] upper_lim,
    output wire out_of_range
);
    assign out_of_range = (in_value < lower_lim) || (in_value > upper_lim);
endmodule