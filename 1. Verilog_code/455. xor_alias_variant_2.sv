//SystemVerilog
// Top-level module
module xor_alias(
    input  wire in1,
    input  wire in2,
    output wire result
);
    // Directly implement XOR functionality using ^
    // This is more efficient than using separate gates
    assign result = in1 ^ in2;
endmodule

// Inverter sub-module
module inverter(
    input  wire in,
    output wire out
);
    // Invert the input signal
    assign out = ~in;
endmodule

// AND gate sub-module
module and_gate(
    input  wire in1,
    input  wire in2,
    output wire out
);
    // Perform AND operation
    assign out = in1 & in2;
endmodule

// OR gate sub-module
module or_gate(
    input  wire in1,
    input  wire in2,
    output wire out
);
    // Perform OR operation
    assign out = in1 | in2;
endmodule