module open_ended_range_detector(
    input wire [11:0] data,
    input wire [11:0] bound_value,
    input wire direction, // 0=lower_bound_only, 1=upper_bound_only
    output wire in_valid_zone
);
    // Open-ended range checking (either checks only lower or only upper bound)
    assign in_valid_zone = direction ? (data <= bound_value) : (data >= bound_value);
endmodule