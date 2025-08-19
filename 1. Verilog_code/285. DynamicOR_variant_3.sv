//SystemVerilog
// 顶层模块
module DynamicOR(
    input [2:0] shift,
    input [31:0] vec1, vec2,
    output [31:0] res
);
    wire [31:0] shifted_vec1;
    
    // 实例化移位子模块
    BarrelShifter barrel_shifter_inst (
        .shift(shift),
        .data_in(vec1),
        .data_out(shifted_vec1)
    );
    
    // 实例化逻辑运算子模块
    LogicOperation logic_op_inst (
        .operand1(shifted_vec1),
        .operand2(vec2),
        .result(res)
    );
endmodule

// 桶形移位器子模块
module BarrelShifter (
    input [2:0] shift,
    input [31:0] data_in,
    output [31:0] data_out
);
    wire [31:0] stage0, stage1;
    
    // 第一级桶形移位：移动0或1位
    ShiftStage #(.SHIFT_AMOUNT(1)) stage0_shifter (
        .shift_enable(shift[0]),
        .data_in(data_in),
        .data_out(stage0)
    );
    
    // 第二级桶形移位：移动0或2位
    ShiftStage #(.SHIFT_AMOUNT(2)) stage1_shifter (
        .shift_enable(shift[1]),
        .data_in(stage0),
        .data_out(stage1)
    );
    
    // 第三级桶形移位：移动0或4位
    ShiftStage #(.SHIFT_AMOUNT(4)) stage2_shifter (
        .shift_enable(shift[2]),
        .data_in(stage1),
        .data_out(data_out)
    );
endmodule

// 参数化移位阶段子模块
module ShiftStage #(
    parameter SHIFT_AMOUNT = 1
)(
    input shift_enable,
    input [31:0] data_in,
    output [31:0] data_out
);
    assign data_out = shift_enable ? 
                     {data_in[31-SHIFT_AMOUNT:0], {SHIFT_AMOUNT{1'b0}}} :
                     data_in;
endmodule

// 逻辑运算子模块
module LogicOperation (
    input [31:0] operand1,
    input [31:0] operand2,
    output [31:0] result
);
    assign result = operand1 | operand2;
endmodule