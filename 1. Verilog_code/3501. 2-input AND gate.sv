// 2-input AND gate
module and_gate_2 (
    input wire a,  // Input A
    input wire b,  // Input B
    output wire y  // Output Y
);
    assign y = a & b;  // AND operation
endmodule
