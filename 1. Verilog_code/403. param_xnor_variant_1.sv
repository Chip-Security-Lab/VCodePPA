//SystemVerilog
// 顶层模块
module param_xnor #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    wire [WIDTH-1:0] and_result;
    wire [WIDTH-1:0] nor_result;
    wire [WIDTH-1:0] a_inv, b_inv;
    
    // 对输入信号进行求反
    inverter #(.WIDTH(WIDTH)) inv_a (
        .data_in(A),
        .data_out(a_inv)
    );
    
    inverter #(.WIDTH(WIDTH)) inv_b (
        .data_in(B),
        .data_out(b_inv)
    );
    
    // 执行与操作 (A & B)
    bit_and #(.WIDTH(WIDTH)) and_gate (
        .a(A),
        .b(B),
        .y(and_result)
    );
    
    // 执行与操作 (~A & ~B)
    bit_and #(.WIDTH(WIDTH)) nor_gate (
        .a(a_inv),
        .b(b_inv),
        .y(nor_result)
    );
    
    // 合并结果 (A & B) | (~A & ~B)
    bit_or #(.WIDTH(WIDTH)) or_gate (
        .a(and_result),
        .b(nor_result),
        .y(Y)
    );
endmodule

// 求反子模块
module inverter #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = ~data_in;
endmodule

// 位与子模块
module bit_and #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    assign y = a & b;
endmodule

// 位或子模块
module bit_or #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    assign y = a | b;
endmodule