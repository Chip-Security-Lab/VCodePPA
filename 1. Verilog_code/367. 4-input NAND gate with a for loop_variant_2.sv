//SystemVerilog - IEEE 1364-2005
module nand4_4 (
    input wire [3:0] A,
    input wire [3:0] B, 
    input wire [3:0] C,
    input wire [3:0] D,
    output wire [3:0] Y
);
    // 内部连线
    wire [3:0] inverted_A;
    wire [3:0] inverted_B;
    wire [3:0] inverted_C;
    wire [3:0] inverted_D;
    
    // 实例化各子模块
    input_inverter inv_A_inst (
        .data_in(A),
        .data_out(inverted_A)
    );
    
    input_inverter inv_B_inst (
        .data_in(B),
        .data_out(inverted_B)
    );
    
    input_inverter inv_C_inst (
        .data_in(C),
        .data_out(inverted_C)
    );
    
    input_inverter inv_D_inst (
        .data_in(D),
        .data_out(inverted_D)
    );
    
    or_combiner or_comb_inst (
        .in_A(inverted_A),
        .in_B(inverted_B),
        .in_C(inverted_C),
        .in_D(inverted_D),
        .result(Y)
    );
endmodule

// 信号求反子模块
module input_inverter (
    input wire [3:0] data_in,
    output wire [3:0] data_out
);
    // 对输入信号求反
    assign data_out = ~data_in;
endmodule

// OR组合逻辑子模块
module or_combiner (
    input wire [3:0] in_A,
    input wire [3:0] in_B,
    input wire [3:0] in_C,
    input wire [3:0] in_D,
    output wire [3:0] result
);
    // 实现OR逻辑
    assign result = in_A | in_B | in_C | in_D;
endmodule