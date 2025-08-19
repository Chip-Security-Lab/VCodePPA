//SystemVerilog
module mux_based_shifter (
    input [7:0] data,
    input [2:0] shift,
    output [7:0] result
);
    wire [7:0] stage1_out, stage2_out;
    
    // 单位移位子模块实例化
    shift_stage1 u_shift_stage1 (
        .data_in(data),
        .shift_en(shift[0]),
        .data_out(stage1_out)
    );
    
    shift_stage2 u_shift_stage2 (
        .data_in(stage1_out),
        .shift_en(shift[1]),
        .data_out(stage2_out)
    );
    
    shift_stage3 u_shift_stage3 (
        .data_in(stage2_out),
        .shift_en(shift[2]),
        .data_out(result)
    );
endmodule

// 第一阶段：循环右移1位子模块
module shift_stage1 (
    input [7:0] data_in,
    input shift_en,
    output [7:0] data_out
);
    // 参数化实现，便于扩展位宽
    assign data_out = shift_en ? {data_in[6:0], data_in[7]} : data_in;
endmodule

// 第二阶段：循环右移2位子模块
module shift_stage2 (
    input [7:0] data_in,
    input shift_en,
    output [7:0] data_out
);
    assign data_out = shift_en ? {data_in[5:0], data_in[7:6]} : data_in;
endmodule

// 第三阶段：循环右移4位子模块
module shift_stage3 (
    input [7:0] data_in,
    input shift_en,
    output [7:0] data_out
);
    assign data_out = shift_en ? {data_in[3:0], data_in[7:4]} : data_in;
endmodule