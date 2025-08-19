//SystemVerilog
module prio_queue #(parameter DW=9, SIZE=4) (
    input  [DW*SIZE-1:0] data_in,
    output [DW-1:0]      data_out
);
    // 分割输入数据为独立项
    wire [DW-1:0] entries [0:SIZE-1];

    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin: entry_split
            assign entries[i] = data_in[(i+1)*DW-1:i*DW];
        end
    endgenerate

    wire [DW-1:0] diff_3_2, diff_2_1, diff_1_0;
    wire borrow_flag_3_2, borrow_flag_2_1, borrow_flag_1_0;

    // 9位二进制补码减法器实例化
    twos_complement_subtractor_9 sub_inst_3_2 (
        .minuend(entries[3]),
        .subtrahend(entries[2]),
        .difference(diff_3_2),
        .borrow_out(borrow_flag_3_2)
    );

    twos_complement_subtractor_9 sub_inst_2_1 (
        .minuend(entries[2]),
        .subtrahend(entries[1]),
        .difference(diff_2_1),
        .borrow_out(borrow_flag_2_1)
    );

    twos_complement_subtractor_9 sub_inst_1_0 (
        .minuend(entries[1]),
        .subtrahend(entries[0]),
        .difference(diff_1_0),
        .borrow_out(borrow_flag_1_0)
    );

    reg [DW-1:0] data_out_reg;
    always @(*) begin
        if (|diff_3_2) begin
            data_out_reg = entries[3];
        end else if (|diff_2_1) begin
            data_out_reg = entries[2];
        end else if (|diff_1_0) begin
            data_out_reg = entries[1];
        end else begin
            data_out_reg = entries[0];
        end
    end

    assign data_out = data_out_reg;

endmodule

// 9位二进制补码减法器
module twos_complement_subtractor_9 (
    input  [8:0] minuend,
    input  [8:0] subtrahend,
    output [8:0] difference,
    output       borrow_out
);
    wire [8:0] subtrahend_inverted;
    wire [8:0] sum_result;
    wire       carry_out;

    assign subtrahend_inverted = ~subtrahend;
    assign {carry_out, sum_result} = {1'b0, minuend} + {1'b0, subtrahend_inverted} + 10'b1;

    assign difference = sum_result[8:0];
    assign borrow_out = ~carry_out;

endmodule