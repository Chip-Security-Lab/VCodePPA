//SystemVerilog
module or_gate_2input_8bit_generate (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] y
);
    // 实例化两个4位或门子模块
    or_gate_4bit or_low (
        .a_in(a[3:0]),
        .b_in(b[3:0]),
        .y_out(y[3:0])
    );
    
    or_gate_4bit or_high (
        .a_in(a[7:4]),
        .b_in(b[7:4]),
        .y_out(y[7:4])
    );
endmodule

// 4位或门子模块
module or_gate_4bit (
    input wire [3:0] a_in,
    input wire [3:0] b_in,
    output wire [3:0] y_out
);
    // 实例化两个2位或门子模块
    or_gate_2bit or_low (
        .a(a_in[1:0]),
        .b(b_in[1:0]),
        .y(y_out[1:0])
    );
    
    or_gate_2bit or_high (
        .a(a_in[3:2]),
        .b(b_in[3:2]),
        .y(y_out[3:2])
    );
endmodule

// 2位或门子模块，基本构建块
module or_gate_2bit (
    input wire [1:0] a,
    input wire [1:0] b,
    output wire [1:0] y
);
    // 使用参数化设计实现简化的或运算
    parameter OPTIMIZE_DELAY = 1; // 可调参数用于优化延迟

    // 使用条件运算符替代if-else结构
    assign y = OPTIMIZE_DELAY ? (a | b) : {a[1] | b[1], a[0] | b[0]};
endmodule