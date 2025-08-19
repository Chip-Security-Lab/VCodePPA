//SystemVerilog
module range_detector_param #(
    parameter DATA_WIDTH = 32
)(
    input wire [DATA_WIDTH-1:0] data,
    input wire [DATA_WIDTH-1:0] lower, upper,
    output wire in_bounds
);
    optimized_comparator #(.WIDTH(DATA_WIDTH)) comp_unit (
        .input_data(data),
        .lower_threshold(lower),
        .upper_threshold(upper),
        .in_range(in_bounds)
    );
endmodule

module optimized_comparator #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] input_data,
    input wire [WIDTH-1:0] lower_threshold,
    input wire [WIDTH-1:0] upper_threshold,
    output reg in_range
);
    // 比较结果信号
    reg lower_check_reg, upper_check_reg;
    
    // 计算与下界的差值
    wire [WIDTH:0] lower_diff;
    assign lower_diff = {1'b0, input_data} - {1'b0, lower_threshold};
    
    // 计算与上界的差值
    wire [WIDTH:0] upper_diff;
    assign upper_diff = {1'b0, upper_threshold} - {1'b0, input_data};
    
    // 下界比较逻辑
    always @(*) begin
        lower_check_reg = ~lower_diff[WIDTH];
    end
    
    // 上界比较逻辑
    always @(*) begin
        upper_check_reg = ~upper_diff[WIDTH];
    end
    
    // 范围判断逻辑
    always @(*) begin
        in_range = lower_check_reg && upper_check_reg;
    end
endmodule