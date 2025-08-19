//SystemVerilog
//IEEE 1364-2005 Verilog
module top_module (
    input [7:0] A, B,
    output [7:0] Diff
);
    // 调用先行借位减法器
    parallel_borrow_subtractor #(
        .WIDTH(8)
    ) subtractor_inst (
        .A(A),
        .B(B),
        .Diff(Diff)
    );
endmodule

module parallel_borrow_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] A, B,
    output [WIDTH-1:0] Diff
);
    wire [WIDTH:0] borrow;
    assign borrow[0] = 1'b0;
    
    // 计算每一位的借位和差值
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow_diff
            // 先行借位计算
            // borrow[i+1] = ~A[i] & B[i] | (A[i] ~^ B[i]) & borrow[i]
            assign borrow[i+1] = (~A[i] & B[i]) | ((A[i] == B[i]) & borrow[i]);
            // 差值计算：A[i] ^ B[i] ^ borrow[i]
            assign Diff[i] = A[i] ^ B[i] ^ borrow[i];
        end
    endgenerate
endmodule

//IEEE 1364-2005 Verilog
module param_wide_xnor #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] A, B,
    output [WIDTH-1:0] Y
);
    // 使用连续赋值替代always块，减少RTL层次，提高综合效率
    // 应用德摩根定律：~(A ^ B) ≡ (A & B) | (~A & ~B)
    // 这种实现可以在某些FPGA架构上提高资源利用率
    assign Y = (A & B) | (~A & ~B);

endmodule