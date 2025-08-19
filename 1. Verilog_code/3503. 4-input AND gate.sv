// 4-input AND gate
module and_gate_4 (
    input wire a,  // Input A
    input wire b,  // Input B
    input wire c,  // Input C
    input wire d,  // Input D
    output wire y  // Output Y
);
    assign y = a & b & c & d;  // AND operation
endmodule
