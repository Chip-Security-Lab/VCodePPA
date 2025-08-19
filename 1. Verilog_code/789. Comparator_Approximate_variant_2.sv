//SystemVerilog
module Comparator_Approximate #(
    parameter WIDTH = 10,
    parameter THRESHOLD = 3
)(
    input  [WIDTH-1:0] data_p,
    input  [WIDTH-1:0] data_q,
    output             approx_eq
);

    wire [WIDTH-1:0] abs_diff;

    Abs_Difference #(
        .WIDTH(WIDTH)
    ) abs_diff_inst (
        .data_p(data_p),
        .data_q(data_q),
        .abs_diff(abs_diff)
    );

    Threshold_Compare #(
        .WIDTH(WIDTH),
        .THRESHOLD(THRESHOLD)
    ) threshold_inst (
        .abs_diff(abs_diff),
        .approx_eq(approx_eq)
    );

endmodule

module Abs_Difference #(
    parameter WIDTH = 10
)(
    input  [WIDTH-1:0] data_p,
    input  [WIDTH-1:0] data_q,
    output [WIDTH-1:0] abs_diff
);

    wire [WIDTH-1:0] diff_pq;
    wire [WIDTH-1:0] diff_qp;
    wire            p_gt_q;

    assign diff_pq = data_p - data_q;
    assign diff_qp = data_q - data_p;
    assign p_gt_q = (data_p > data_q);

    assign abs_diff = p_gt_q ? diff_pq : diff_qp;

endmodule

module Threshold_Compare #(
    parameter WIDTH = 10,
    parameter THRESHOLD = 3
)(
    input  [WIDTH-1:0] abs_diff,
    output             approx_eq
);

    assign approx_eq = (abs_diff <= THRESHOLD);

endmodule