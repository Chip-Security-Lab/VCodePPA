module task_based(
    input [3:0] in,
    output [1:0] out
);

    // 子模块：处理输入数据
    process_unit process_inst(
        .i(in),
        .o(out)
    );

endmodule

module process_unit(
    input [3:0] i,
    output [1:0] o
);
    assign o = {i[3], ^i[2:0]};
endmodule