//SystemVerilog
module shift_compare_top (
    input [4:0] x,
    input [4:0] y,
    output [4:0] shift_left,
    output [4:0] shift_right,
    output equal
);

    // 合并移位和比较逻辑，减少模块层次
    assign shift_left = {x[3:0], 1'b0};
    assign shift_right = {1'b0, y[4:1]};
    assign equal = ~|(x ^ y);

endmodule