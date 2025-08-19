// 2-input AND gate with reset functionality
module and_gate_reset (
    input wire a,      // Input A
    input wire b,      // Input B
    input wire rst,    // Reset signal
    output wire y      // Output Y
);
    assign y = (rst) ? 0 : (a & b);  // AND operation with reset
endmodule
