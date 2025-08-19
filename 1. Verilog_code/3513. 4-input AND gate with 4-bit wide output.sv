// 4-input AND gate (4-bit wide)
module and_gate_4bit (
    input wire [3:0] a,  // 4-bit input A
    input wire [3:0] b,  // 4-bit input B
    input wire [3:0] c,  // 4-bit input C
    input wire [3:0] d,  // 4-bit input D
    output wire [3:0] y  // 4-bit output Y
);
    assign y = a & b & c & d;  // AND operation on 4 inputs
endmodule

