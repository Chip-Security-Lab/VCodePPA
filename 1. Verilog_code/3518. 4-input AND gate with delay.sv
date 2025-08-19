// 4-input AND gate with delay
module and_gate_4_delay (
    input wire a,  // Input A
    input wire b,  // Input B
    input wire c,  // Input C
    input wire d,  // Input D
    output reg y   // Output Y
);
    always @(a, b, c, d) begin
        #3 y = a & b & c & d;  // AND operation with 3-time unit delay
    end
endmodule
