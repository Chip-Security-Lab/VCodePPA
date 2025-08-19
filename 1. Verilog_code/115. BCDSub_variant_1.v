module BCDSub(input [7:0] bcd_a, bcd_b, output [7:0] bcd_res);
    wire [7:0] raw_diff;
    wire borrow;
    wire [7:0] adjusted_diff;
    
    // 计算原始差值
    BCDRawDiff raw_diff_inst(
        .bcd_a(bcd_a),
        .bcd_b(bcd_b),
        .raw_diff(raw_diff),
        .borrow(borrow)
    );
    
    // 调整差值
    BCDAdjust adjust_inst(
        .raw_diff(raw_diff),
        .borrow(borrow),
        .adjusted_diff(adjusted_diff)
    );
    
    assign bcd_res = adjusted_diff;
endmodule

module BCDRawDiff(
    input [7:0] bcd_a,
    input [7:0] bcd_b,
    output [7:0] raw_diff,
    output borrow
);
    assign {borrow, raw_diff} = bcd_a - bcd_b;
endmodule

module BCDAdjust(
    input [7:0] raw_diff,
    input borrow,
    output [7:0] adjusted_diff
);
    assign adjusted_diff = borrow ? (raw_diff - 6'h6) : raw_diff;
endmodule