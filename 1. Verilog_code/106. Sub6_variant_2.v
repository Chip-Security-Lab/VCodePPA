// 减法运算子模块
module SubtractionCore(
    input [7:0] operand_a,
    input [7:0] operand_b,
    output [7:0] difference
);
    assign difference = operand_a - operand_b;
endmodule

// 使能控制子模块
module EnableGate(
    input [7:0] data_input,
    input enable_signal,
    output [7:0] data_output
);
    assign data_output = enable_signal ? data_input : 8'b0;
endmodule

// 顶层模块
module Sub6(
    input [7:0] a,
    input [7:0] b,
    input en,
    output [7:0] res
);
    wire [7:0] intermediate_result;
    
    SubtractionCore sub_core(
        .operand_a(a),
        .operand_b(b),
        .difference(intermediate_result)
    );
    
    EnableGate enable_gate(
        .data_input(intermediate_result),
        .enable_signal(en),
        .data_output(res)
    );
endmodule