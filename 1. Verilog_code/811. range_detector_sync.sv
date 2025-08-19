module range_detector_sync(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire [7:0] lower_bound, upper_bound,
    output reg in_range
);
    wire compare_result;
    
    comparator comp_inst (
        .data(data_in),
        .lower(lower_bound),
        .upper(upper_bound),
        .result(compare_result)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) in_range <= 1'b0;
        else in_range <= compare_result;
    end
endmodule

// 添加缺失的comparator模块
module comparator(
    input wire [7:0] data,
    input wire [7:0] lower,
    input wire [7:0] upper,
    output wire result
);
    assign result = (data >= lower) && (data <= upper);
endmodule