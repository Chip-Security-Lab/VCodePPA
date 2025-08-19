//SystemVerilog
module RangeDetector_BoundType #(
    parameter WIDTH = 8,
    parameter INCLUSIVE = 1 // 0:exclusive
)(
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output out_flag
);
    // 实例化范围比较器模块
    RangeComparator #(
        .WIDTH(WIDTH),
        .INCLUSIVE(INCLUSIVE)
    ) comparator_inst (
        .data_in(data_in),
        .lower(lower),
        .upper(upper),
        .in_range(out_flag)
    );
endmodule

module RangeComparator #(
    parameter WIDTH = 8,
    parameter INCLUSIVE = 1 // 0:exclusive
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg in_range
);
    // 进行下界检查
    wire lower_check;
    // 进行上界检查
    wire upper_check;
    
    // 根据INCLUSIVE参数选择比较方式
    LowerBoundCheck #(
        .WIDTH(WIDTH),
        .INCLUSIVE(INCLUSIVE)
    ) lower_check_inst (
        .data_in(data_in),
        .bound(lower),
        .result(lower_check)
    );
    
    UpperBoundCheck #(
        .WIDTH(WIDTH),
        .INCLUSIVE(INCLUSIVE)
    ) upper_check_inst (
        .data_in(data_in),
        .bound(upper),
        .result(upper_check)
    );
    
    // 合并检查结果
    always @(*) begin
        in_range = lower_check && upper_check;
    end
endmodule

module LowerBoundCheck #(
    parameter WIDTH = 8,
    parameter INCLUSIVE = 1 // 0:exclusive
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] bound,
    output reg result
);
    always @(*) begin
        if (INCLUSIVE)
            result = (data_in >= bound);
        else
            result = (data_in > bound);
    end
endmodule

module UpperBoundCheck #(
    parameter WIDTH = 8,
    parameter INCLUSIVE = 1 // 0:exclusive
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] bound,
    output reg result
);
    always @(*) begin
        if (INCLUSIVE)
            result = (data_in <= bound);
        else
            result = (data_in < bound);
    end
endmodule