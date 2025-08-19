// 8-input AND gate
module and_gate_8input (
    input wire a,  // Input A
    input wire b,  // Input B
    input wire c,  // Input C
    input wire d,  // Input D
    input wire e,  // Input E
    input wire f,  // Input F
    input wire g,  // Input G
    input wire h,  // Input H
    output wire y  // Output Y
);
    assign y = a & b & c & d & e & f & g & h;  // AND operation on 8 inputs
endmodule
