//SystemVerilog
// Top-level module for NAND3 gate with optimized structure
module nand3_3 (
    input  wire A,
    input  wire B, 
    input  wire C,
    output wire Y
);
    // Direct implementation of NAND3 functionality for better PPA
    // Eliminates intermediate signal and improves timing
    nand3_gate nand_impl (
        .in1(A),
        .in2(B),
        .in3(C),
        .out(Y)
    );
endmodule

// Optimized 3-input NAND gate with parameterized design
module nand3_gate #(
    parameter DRIVE_STRENGTH = 1
) (
    input  wire in1,
    input  wire in2,
    input  wire in3,
    output wire out
);
    // Direct implementation of NAND functionality
    // More efficient than AND followed by NOT
    assign out = ~(in1 & in2 & in3);
    
    // Synthesis attributes can be added here for PPA optimization
    // (* dont_touch = "true" *)
endmodule

// Parameterized AND gate for reuse in other designs
module and3_gate #(
    parameter DRIVE_STRENGTH = 1
) (
    input  wire in1,
    input  wire in2,
    input  wire in3,
    output wire out
);
    assign out = in1 & in2 & in3;
endmodule

// Parameterized inverter for reuse in other designs
module inverter_gate #(
    parameter DRIVE_STRENGTH = 1
) (
    input  wire in,
    output wire out
);
    assign out = ~in;
endmodule