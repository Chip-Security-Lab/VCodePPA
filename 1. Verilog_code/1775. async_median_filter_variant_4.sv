//SystemVerilog
module async_median_filter #(
    parameter W = 16
)(
    input [W-1:0] a, b, c,
    output [W-1:0] med_out
);
    wire [W-1:0] min_ab, max_ab;
    
    minmax_comparator #(
        .WIDTH(W)
    ) comp_ab (
        .in1(a),
        .in2(b),
        .min_out(min_ab),
        .max_out(max_ab)
    );
    
    median_selector #(
        .WIDTH(W)
    ) med_sel (
        .min_val(min_ab),
        .max_val(max_ab),
        .third_val(c),
        .median(med_out)
    );
endmodule

module minmax_comparator #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in1, in2,
    output [WIDTH-1:0] min_out, max_out
);
    wire [WIDTH-1:0] diff;
    assign diff = in1 - in2;
    assign min_out = (diff[WIDTH-1]) ? in1 : in2;
    assign max_out = (diff[WIDTH-1]) ? in2 : in1;
endmodule

module median_selector #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] min_val, max_val, third_val,
    output [WIDTH-1:0] median
);
    wire [WIDTH-1:0] diff_min, diff_max;
    wire [WIDTH-1:0] sel_min, sel_max, sel_third;
    
    assign diff_min = third_val - min_val;
    assign diff_max = third_val - max_val;
    
    assign sel_min = {WIDTH{diff_min[WIDTH-1]}};
    assign sel_max = {WIDTH{~diff_max[WIDTH-1]}};
    assign sel_third = ~(sel_min | sel_max);
    
    assign median = (sel_min & min_val) | (sel_max & max_val) | (sel_third & third_val);
endmodule