module range_detector_with_enable(
    input wire clk, rst, enable,
    input wire [15:0] data_input,
    input wire [15:0] range_min, range_max,
    output reg range_detect_flag
);
    wire comp_out;
    
    comparator_module comp1(
        .data(data_input),
        .lower(range_min),
        .upper(range_max),
        .in_range(comp_out)
    );
    
    always @(posedge clk) begin
        if (rst) range_detect_flag <= 1'b0;
        else if (enable) range_detect_flag <= comp_out;
    end
endmodule

// 添加缺失的comparator_module
module comparator_module(
    input wire [15:0] data,
    input wire [15:0] lower,
    input wire [15:0] upper,
    output wire in_range
);
    assign in_range = (data >= lower) && (data <= upper);
endmodule