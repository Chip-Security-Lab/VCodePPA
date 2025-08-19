//SystemVerilog
module shift_arith_async #(parameter W=8) (
    input  signed [W-1:0] din,
    input        [2:0]    shift,
    output signed [W-1:0] dout
);
    wire signed [W-1:0] stage0;
    wire signed [W-1:0] stage1;
    wire signed [W-1:0] stage2;

    // Stage 0: shift by 1 if shift[0]
    assign stage0 = shift[0] ? {din[W-1], din[W-1:1]} : din;

    // Stage 1: shift by 2 if shift[1]
    assign stage1 = shift[1] ? {{2{stage0[W-1]}}, stage0[W-1:2]} : stage0;

    // Stage 2: shift by 4 if shift[2]
    assign stage2 = shift[2] ? {{4{stage1[W-1]}}, stage1[W-1:4]} : stage1;

    assign dout = stage2;

endmodule