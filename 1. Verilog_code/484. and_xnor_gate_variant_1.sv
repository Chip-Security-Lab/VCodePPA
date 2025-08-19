//SystemVerilog - IEEE 1364-2005 Standard
module and_xnor_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 内部连线
    wire and_result;
    wire term1, term2, term3;
    
    // 实例化子模块
    and_logic and_comp (
        .in1(A),
        .in2(B),
        .out(and_result)
    );
    
    term_generator term_gen (
        .and_in(and_result),
        .c_in(C),
        .a_in(A),
        .b_in(B),
        .term1_out(term1),
        .term2_out(term2),
        .term3_out(term3)
    );
    
    or_logic or_comp (
        .in1(term1),
        .in2(term2),
        .in3(term3),
        .out(Y)
    );
endmodule

// AND 逻辑子模块
module and_logic (
    input wire in1, in2,
    output wire out
);
    assign out = in1 & in2;
endmodule

// 项生成子模块
module term_generator (
    input wire and_in, c_in, a_in, b_in,
    output wire term1_out, term2_out, term3_out
);
    // 生成三个项: (A & B & C), (~A & ~C), (~B & ~C)
    assign term1_out = and_in & c_in;
    assign term2_out = ~a_in & ~c_in;
    assign term3_out = ~b_in & ~c_in;
endmodule

// OR 逻辑子模块
module or_logic (
    input wire in1, in2, in3,
    output wire out
);
    assign out = in1 | in2 | in3;
endmodule