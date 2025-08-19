module exclusive_range_detector(
    input wire clk,
    input wire [9:0] data_val,
    input wire [9:0] lower_val, upper_val,
    input wire inclusive, // 0=exclusive, 1=inclusive
    output reg range_match
);
    wire temp_result;
    wire low_check = inclusive ? (data_val >= lower_val) : (data_val > lower_val);
    wire high_check = inclusive ? (data_val <= upper_val) : (data_val < upper_val);
    
    assign temp_result = low_check && high_check;
    
    always @(posedge clk) range_match <= temp_result;
endmodule