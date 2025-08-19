//SystemVerilog
//-----------------------------------------------------------------------------
// File: nand_gate_top.v
// Description: 8-bit NAND gate top module with hierarchical structure
//-----------------------------------------------------------------------------
module nand2_5 (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [7:0] Y
);

    // Instantiate optimized bit slices for improved PPA characteristics
    nand_bit_slice slice0 (.a(A[0]), .b(B[0]), .y(Y[0]));
    nand_bit_slice slice1 (.a(A[1]), .b(B[1]), .y(Y[1]));
    nand_bit_slice slice2 (.a(A[2]), .b(B[2]), .y(Y[2]));
    nand_bit_slice slice3 (.a(A[3]), .b(B[3]), .y(Y[3]));
    
    // Using an optimized 4-bit slice module for the upper bits
    nand_nibble_slice upper_nibble (
        .a_nibble(A[7:4]),
        .b_nibble(B[7:4]),
        .y_nibble(Y[7:4])
    );

endmodule

//-----------------------------------------------------------------------------
// Single-bit NAND slice with direct implementation for optimal timing
//-----------------------------------------------------------------------------
module nand_bit_slice (
    input  wire a,
    input  wire b,
    output wire y
);
    // Direct NAND implementation eliminates intermediate signal and reduces
    // logic depth for better timing and lower power consumption
    assign y = ~(a & b);
    
endmodule

//-----------------------------------------------------------------------------
// 4-bit NAND slice with optimized implementation
//-----------------------------------------------------------------------------
module nand_nibble_slice (
    input  wire [3:0] a_nibble,
    input  wire [3:0] b_nibble,
    output wire [3:0] y_nibble
);
    
    // Parameter for implementation strategy selection
    parameter OPTIMIZE_FOR = "AREA"; // Options: "AREA", "SPEED", "POWER"
    
    // Direct vector-level NAND operation reduces code complexity
    // and allows synthesis tools to better optimize the implementation
    assign y_nibble = ~(a_nibble & b_nibble);
    
endmodule