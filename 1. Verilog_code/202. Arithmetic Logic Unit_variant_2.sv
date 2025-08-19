//SystemVerilog
module arithmetic_logic_unit (
    input [7:0] a,
    input [7:0] b,
    input [1:0] op_select,  // 00: add, 01: subtract, 10: and, 11: or
    output [7:0] result
);
    // 使用组合逻辑实现，避免不必要的寄存器
    wire [7:0] add_result, sub_result, and_result, or_result;
    
    // 并行计算所有可能的结果
    assign add_result = a + b;
    assign sub_result = a - b;
    assign and_result = a & b;
    assign or_result = a | b;
    
    // 使用多路选择器选择最终结果
    assign result = (op_select == 2'b00) ? add_result :
                    (op_select == 2'b01) ? sub_result :
                    (op_select == 2'b10) ? and_result :
                    (op_select == 2'b11) ? or_result : 8'b0;
endmodule