// 2-bit AND gate
module and_gate_2bit (
    input wire [1:0] a,  // 2-bit input A
    input wire [1:0] b,  // 2-bit input B
    output wire [1:0] y  // 2-bit output Y
);
    assign y = a & b;  // AND operation on 2 bits
endmodule
