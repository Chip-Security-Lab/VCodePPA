//SystemVerilog
// 顶层模块
module barrel_shifter_comb_lr (
    input [15:0] din,
    input [3:0] shift,
    output [15:0] dout
);
    // 内部连线
    wire [15:0] shift_stage1_out;
    wire [15:0] shift_stage2_out;
    wire [15:0] shift_stage3_out;
    
    // 移位阶段子模块实例化
    shift_stage1 u_shift_stage1 (
        .data_in(din),
        .shift_en(shift[0]),
        .data_out(shift_stage1_out)
    );
    
    shift_stage2 u_shift_stage2 (
        .data_in(shift_stage1_out),
        .shift_en(shift[1]),
        .data_out(shift_stage2_out)
    );
    
    shift_stage4 u_shift_stage3 (
        .data_in(shift_stage2_out),
        .shift_en(shift[2]),
        .data_out(shift_stage3_out)
    );
    
    shift_stage8 u_shift_stage4 (
        .data_in(shift_stage3_out),
        .shift_en(shift[3]),
        .data_out(dout)
    );
endmodule

// 子模块：1位移位
module shift_stage1 (
    input [15:0] data_in,
    input shift_en,
    output [15:0] data_out
);
    assign data_out = shift_en ? {1'b0, data_in[15:1]} : data_in;
endmodule

// 子模块：2位移位
module shift_stage2 (
    input [15:0] data_in,
    input shift_en,
    output [15:0] data_out
);
    assign data_out = shift_en ? {2'b0, data_in[15:2]} : data_in;
endmodule

// 子模块：4位移位
module shift_stage4 (
    input [15:0] data_in,
    input shift_en,
    output [15:0] data_out
);
    assign data_out = shift_en ? {4'b0, data_in[15:4]} : data_in;
endmodule

// 子模块：8位移位
module shift_stage8 (
    input [15:0] data_in,
    input shift_en,
    output [15:0] data_out
);
    assign data_out = shift_en ? {8'b0, data_in[15:8]} : data_in;
endmodule