//SystemVerilog
// 顶层模块 - 集成移位与位运算功能
module Shift_AND #(
    parameter DATA_WIDTH = 32
)(
    input [2:0] shift_ctrl,
    input [DATA_WIDTH-1:0] vec,
    output [DATA_WIDTH-1:0] out
);
    // 内部连线
    wire [DATA_WIDTH-1:0] mask;
    
    // 子模块实例化
    Mask_Generator #(
        .WIDTH(DATA_WIDTH)
    ) mask_gen (
        .shift_amount(shift_ctrl),
        .mask_out(mask)
    );
    
    Bitwise_Operator #(
        .WIDTH(DATA_WIDTH),
        .OPERATION("AND")
    ) bit_and (
        .operand_a(vec),
        .operand_b(mask),
        .result(out)
    );
endmodule

// 掩码生成器子模块 - 可参数化的掩码生成
module Mask_Generator #(
    parameter WIDTH = 32
)(
    input [2:0] shift_amount,
    output reg [WIDTH-1:0] mask_out
);
    // 使用always块进行掩码生成以优化时序和面积
    always @(*) begin
        mask_out = {WIDTH{1'b1}} << shift_amount;
    end
endmodule

// 可配置位运算子模块 - 支持多种位操作
module Bitwise_Operator #(
    parameter WIDTH = 32,
    parameter OPERATION = "AND"  // 支持未来扩展其他位运算
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output reg [WIDTH-1:0] result
);
    // 实现可配置的位运算操作
    always @(*) begin
        case (OPERATION)
            "AND": result = operand_a & operand_b;
            "OR":  result = operand_a | operand_b;  // 为未来扩展预留
            "XOR": result = operand_a ^ operand_b;  // 为未来扩展预留
            default: result = operand_a & operand_b;
        endcase
    end
endmodule