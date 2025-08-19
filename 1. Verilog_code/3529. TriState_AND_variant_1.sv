//SystemVerilog
// 顶层模块
module TriState_AND(
    input oe_n,       // 低有效使能
    input [3:0] x, y,
    output [3:0] z
);
    // 内部连线
    wire [3:0] and_result;
    
    // 实例化AND逻辑子模块
    Logic_AND_Unit and_unit (
        .x_in(x),
        .y_in(y),
        .result(and_result)
    );
    
    // 实例化三态缓冲控制子模块
    TriState_Buffer_Unit tri_buffer (
        .data_in(and_result),
        .oe_n(oe_n),
        .data_out(z)
    );
    
endmodule

// 逻辑与运算子模块
module Logic_AND_Unit (
    input [3:0] x_in,
    input [3:0] y_in,
    output [3:0] result
);
    // 参数化实现，便于后续扩展位宽
    parameter WIDTH = 4;
    
    // 执行与操作
    assign result = x_in & y_in;
    
endmodule

// 三态缓冲控制子模块
module TriState_Buffer_Unit (
    input [3:0] data_in,
    input oe_n,
    output reg [3:0] data_out
);
    // 参数化实现，便于后续扩展位宽
    parameter WIDTH = 4;
    
    // 使用always块替代条件运算符，根据使能信号控制输出
    always @(*)
    begin
        if (oe_n)
            data_out = {WIDTH{1'bz}};
        else
            data_out = data_in;
    end
    
endmodule