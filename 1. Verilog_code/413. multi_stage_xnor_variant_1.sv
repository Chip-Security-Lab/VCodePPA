//SystemVerilog
// 顶层模块
module multi_stage_xnor (
    input  wire [3:0] data_a, data_b,
    output wire [3:0] result
);
    wire [3:0] and_result;
    wire [3:0] nand_result;
    wire [3:0] inverted_a;
    wire [3:0] inverted_b;
    
    // 子模块实例化
    inverter inv_a_inst (
        .data_in(data_a),
        .data_out(inverted_a)
    );
    
    inverter inv_b_inst (
        .data_in(data_b),
        .data_out(inverted_b)
    );
    
    bit_and and_inst (
        .data_a(data_a),
        .data_b(data_b),
        .result(and_result)
    );
    
    bit_and nand_inst (
        .data_a(inverted_a),
        .data_b(inverted_b),
        .result(nand_result)
    );
    
    bit_or or_inst (
        .data_a(and_result),
        .data_b(nand_result),
        .result(result)
    );
    
endmodule

// 反相器子模块
module inverter (
    input  wire [3:0] data_in,
    output wire [3:0] data_out
);
    // 对输入数据进行按位取反
    assign data_out = ~data_in;
endmodule

// 位与操作子模块
module bit_and (
    input  wire [3:0] data_a, data_b,
    output wire [3:0] result
);
    // 执行位与操作
    assign result = data_a & data_b;
endmodule

// 位或操作子模块
module bit_or (
    input  wire [3:0] data_a, data_b,
    output wire [3:0] result
);
    // 执行位或操作
    assign result = data_a | data_b;
endmodule