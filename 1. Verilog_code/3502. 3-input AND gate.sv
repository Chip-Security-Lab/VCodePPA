// 3-input AND gate
module and_gate_3 (
    input wire a,  // Input A
    input wire b,  // Input B
    input wire c,  // Input C
    output wire y  // Output Y
);
    assign y = a & b & c;  // AND operation
endmodule
