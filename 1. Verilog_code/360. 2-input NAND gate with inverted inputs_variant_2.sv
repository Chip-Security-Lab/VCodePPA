//SystemVerilog
// Top-level module implementing NAND2 with inverted inputs - optimized
module nand2_4 (
    input  wire A,
    input  wire B, 
    output wire Y
);
    // Using Boolean algebra: ~(~A & ~B) = A | B (De Morgan's law)
    assign Y = A | B;
endmodule

// Inverter module (kept for compatibility)
module inverter (
    input  wire in,
    output wire out
);
    assign out = ~in;
endmodule

// NAND gate module (kept for compatibility)
module nand_gate (
    input  wire in1,
    input  wire in2,
    output wire out
);
    assign out = ~(in1 & in2);
endmodule