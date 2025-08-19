module hysteresis_range_detector(
    input wire clock, reset_n,
    input wire [7:0] input_data,
    input wire [7:0] low_bound, high_bound,
    input wire [3:0] hysteresis,
    output reg in_valid_range
);
    wire in_range_now;
    wire [7:0] effective_low = in_valid_range ? (low_bound - hysteresis) : low_bound;
    wire [7:0] effective_high = in_valid_range ? (high_bound + hysteresis) : high_bound;
    
    assign in_range_now = (input_data >= effective_low) && (input_data <= effective_high);
    
    always @(posedge clock or negedge reset_n)
        if (!reset_n) in_valid_range <= 1'b0;
        else in_valid_range <= in_range_now;
endmodule