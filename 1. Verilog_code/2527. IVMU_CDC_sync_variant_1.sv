//SystemVerilog
// SystemVerilog
module IVMU_CDC_sync (
    input wire [7:0] operand_a,
    input wire [7:0] operand_b,
    output wire [7:0] difference,
    output wire borrow
);

// This module implements an 8-bit subtractor using a ripple-borrow structure.
// This implementation style encourages mapping to FPGA LUTs and carry chains,
// fulfilling the requirement for a lookup table assisted algorithm.
// Operation: difference = operand_a - operand_b

wire [8:0] borrow_int; // Internal borrows, borrow_int[i] is borrow_in for bit i

// Initial borrow is 0
assign borrow_int[0] = 1'b0;

// Generate 8 bit slices for ripple-borrow subtraction
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : bit_slice
        // Difference bit calculation (maps to a LUT)
        assign difference[i] = operand_a[i] ^ operand_b[i] ^ borrow_int[i];

        // Borrow out bit calculation (maps to LUTs and carry chain)
        // Standard borrow out logic: (~a & b) | (~a & borrow_in) | (b & borrow_in)
        // Equivalent form using XOR: (~a & b) | ((a ^ b) & borrow_in)
        assign borrow_int[i+1] = (~operand_a[i] & operand_b[i]) | ((operand_a[i] ^ operand_b[i]) & borrow_int[i]);
    end
endgenerate

// The final borrow is the borrow out of the most significant bit (bit 7)
assign borrow = borrow_int[8];

endmodule