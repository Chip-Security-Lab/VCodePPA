//SystemVerilog
module MuxAsync #(parameter DW=8, AW=3) (
    input [AW-1:0] channel,
    input [2**AW-1:0][DW-1:0] din,
    output reg [DW-1:0] dout
);
    wire [DW-1:0] selected_data;
    reg [DW-1:0] subtrahend;
    wire [DW-1:0] diff;
    wire borrow_out;

    // 多路选择器
    assign selected_data = din[channel];

    // subtrahend赋值独立always块
    always @(*) begin
        subtrahend = 8'd42; // 例：固定减去42，可根据实际需要替换
    end

    ConditionalSumSubtractor8 u_conditional_sum_subtractor8 (
        .minuend(selected_data),
        .subtrahend(subtrahend),
        .difference(diff),
        .borrow(borrow_out)
    );

    // dout赋值独立always块
    always @(*) begin
        dout = diff;
    end

endmodule

module ConditionalSumSubtractor8 (
    input  [7:0] minuend,
    input  [7:0] subtrahend,
    output [7:0] difference,
    output       borrow
);

    wire [7:0] subtrahend_inverted;
    wire [7:0] sum_stage0, sum_stage1, sum_stage2, sum_stage3;
    wire [7:0] carry_stage0, carry_stage1, carry_stage2, carry_stage3;
    wire       carry_in;

    // subtrahend_inverted赋值独立always块
    assign subtrahend_inverted = ~subtrahend;

    // carry_in赋值独立always块
    assign carry_in = 1'b1; // 因为A-B=A+(~B)+1

    // 第一阶段：位0-1
    assign {carry_stage0[1], sum_stage0[0]} = minuend[0] + subtrahend_inverted[0] + carry_in;
    assign {carry_stage0[2], sum_stage0[1]} = minuend[1] + subtrahend_inverted[1] + carry_stage0[1];

    // 第二阶段：位2-3
    assign {carry_stage1[3], sum_stage1[2]} = minuend[2] + subtrahend_inverted[2] + carry_stage0[2];
    assign {carry_stage1[4], sum_stage1[3]} = minuend[3] + subtrahend_inverted[3] + carry_stage1[3];

    // 第三阶段：位4-5
    assign {carry_stage2[5], sum_stage2[4]} = minuend[4] + subtrahend_inverted[4] + carry_stage1[4];
    assign {carry_stage2[6], sum_stage2[5]} = minuend[5] + subtrahend_inverted[5] + carry_stage2[5];

    // 第四阶段：位6-7
    assign {carry_stage3[7], sum_stage3[6]} = minuend[6] + subtrahend_inverted[6] + carry_stage2[6];
    assign {borrow,           sum_stage3[7]} = minuend[7] + subtrahend_inverted[7] + carry_stage3[7];

    // difference赋值独立always块
    assign difference = {sum_stage3[7], sum_stage3[6], sum_stage2[5], sum_stage2[4], sum_stage1[3], sum_stage1[2], sum_stage0[1], sum_stage0[0]};

endmodule