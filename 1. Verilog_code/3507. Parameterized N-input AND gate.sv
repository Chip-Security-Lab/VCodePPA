// Parametrized AND gate
module and_gate_n #(
    parameter N = 4  // Number of inputs
) (
    input wire [N-1:0] a,  // N-bit input A
    input wire [N-1:0] b,  // N-bit input B
    output wire [N-1:0] y  // N-bit output Y
);
    assign y = a & b;  // AND operation on N bits
endmodule
