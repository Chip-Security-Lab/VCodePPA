// 8-bit AND gate
module and_gate_8 (
    input wire [7:0] a,  // 8-bit input A
    input wire [7:0] b,  // 8-bit input B
    output wire [7:0] y  // 8-bit output Y
);
    assign y = a & b;  // AND operation on 8 bits
endmodule
