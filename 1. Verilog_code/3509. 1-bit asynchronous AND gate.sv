// 1-bit asynchronous AND gate
module and_gate_1_async (
    input wire a,  // Input A
    input wire b,  // Input B
    output wire y  // Output Y
);
    // 将过程赋值改为连续赋值以匹配wire输出
    assign y = a & b;  // AND operation
endmodule