// AND gate with enable signal
module and_gate_enable (
    input wire a,      // Input A
    input wire b,      // Input B
    input wire enable, // Enable signal
    output wire y      // Output Y
);
    assign y = (enable) ? (a & b) : 1'b0;  // AND operation with enable
endmodule
