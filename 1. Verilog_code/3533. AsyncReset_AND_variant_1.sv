//SystemVerilog
//-----------------------------------------------------------------------------
// File: AsyncReset_AND_Top.v
// Description: Top module for asynchronous reset AND operation
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module AsyncReset_AND_Top(
    input rst_n,
    input [3:0] src1, src2,
    output [3:0] q
);
    // 内部信号
    wire [3:0] and_result;
    
    // 子模块实例化
    // 位与运算子模块
    BitWiseAND u_bit_wise_and (
        .operand1(src1),
        .operand2(src2),
        .result(and_result)
    );
    
    // 复位控制子模块
    ResetControl u_reset_control (
        .rst_n(rst_n),
        .data_in(and_result),
        .data_out(q)
    );

endmodule

//-----------------------------------------------------------------------------
// File: BitWiseAND.v
// Description: Performs bitwise AND operation on two inputs
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module BitWiseAND #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] operand1,
    input [WIDTH-1:0] operand2,
    output [WIDTH-1:0] result
);
    // 计算位与结果
    assign result = operand1 & operand2;
    
endmodule

//-----------------------------------------------------------------------------
// File: ResetControl.v
// Description: Controls asynchronous reset functionality
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module ResetControl #(
    parameter WIDTH = 4,
    parameter RESET_VALUE = {WIDTH{1'b0}}
)(
    input rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // 使用always块替代条件运算符，提高可读性
    always @(*) begin
        if (rst_n) begin
            data_out = data_in;
        end else begin
            data_out = RESET_VALUE;
        end
    end
    
endmodule