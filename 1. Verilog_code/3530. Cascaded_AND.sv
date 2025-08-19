module Cascaded_AND(
    input [2:0] in,
    output out
);
    wire stage1;
    and(stage1, in[0], in[1]);
    and(out, stage1, in[2]); // 三级级联结构
endmodule
