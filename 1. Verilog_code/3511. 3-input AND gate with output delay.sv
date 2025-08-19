// 3-input AND gate with output delay
module and_gate_3_delay (
    input wire a,  // Input A
    input wire b,  // Input B
    input wire c,  // Input C
    output reg y   // Output Y
);
    always @(a, b, c) begin
        #2 y = a & b & c;  // AND operation with 2-time unit delay
    end
endmodule
