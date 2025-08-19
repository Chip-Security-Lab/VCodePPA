//------------------------------------------------------------------------------
// Module: Adder_7
// Description: Top level module for a 4-bit adder using a hierarchical structure.
// Instantiates the adder_core sub-module to perform the addition.
//------------------------------------------------------------------------------
module Adder_7 (
    input [3:0] A,
    input [3:0] B,
    output reg [4:0] sum
);

    // Internal wire to connect the adder_core output to the top module output.
    // This signal carries the result of the core addition logic.
    wire [4:0] adder_sum_wire;

    // Instantiate the adder_core sub-module.
    // This sub-module encapsulates the core arithmetic operation.
    adder_core u_adder_core (
        .in_a(A),          // Connect input A from top module to adder_core input in_a
        .in_b(B),          // Connect input B from top module to adder_core input in_b
        .out_sum(adder_sum_wire) // Connect adder_core output out_sum to the internal wire
    );

    // Assign the result from the sub-module (via the internal wire)
    // to the output register 'sum'.
    // This assignment is combinational, triggered by changes in the wire,
    // mirroring the behavior of the original always @(*) block.
    always @(*) begin
        sum = adder_sum_wire;
    end

endmodule

//------------------------------------------------------------------------------
// Module: adder_core
// Description: Performs the core 4-bit addition logic using Carry-Skip Adder.
// This sub-module is responsible solely for the arithmetic operation.
//------------------------------------------------------------------------------
module adder_core (
    input [3:0] in_a, // First 4-bit input operand
    input [3:0] in_b, // Second 4-bit input operand
    output [4:0] out_sum // 5-bit output sum (includes carry)
);

    // Carry-Skip Adder (CSA) implementation for 4 bits (2 blocks of 2 bits)

    // Propagate and Generate signals for each bit
    wire [3:0] p; // Propagate: a_i ^ b_i
    wire [3:0] g; // Generate: a_i & b_i

    assign p = in_a ^ in_b;
    assign g = in_a & in_b;

    // Internal carries and block signals
    wire c_b0_c1;           // Carry into bit 1 (within Block 0)
    wire c_b0_cout_ripple;  // Carry out of Block 0 (ripple path)
    wire P_0;               // Propagate for Block 0 (bits 0-1)

    wire c_in_b1;           // Carry into Block 1 (bits 2-3, determined by skip logic)
    wire c_b1_c3;           // Carry into bit 3 (within Block 1)
    wire c_b1_cout_ripple;  // Carry out of Block 1 (ripple path)
    wire P_1;               // Propagate for Block 1 (bits 2-3)

    wire cout;              // Final carry out

    wire [3:0] s;           // Sum bits

    // Assume overall carry-in is 0 for simple A+B
    wire cin = 1'b0;

    // Block 0 (bits 0, 1)
    // Ripple carry within block 0
    assign c_b0_c1 = g[0] | (p[0] & cin);
    assign c_b0_cout_ripple = g[1] | (p[1] & c_b0_c1);
    // Block 0 propagate signal
    assign P_0 = p[0] & p[1];

    // Block 1 (bits 2, 3) - Carry-in determined by skip logic
    // Carry-in to Block 1 is either the initial carry (cin) if Block 0 propagates (P_0),
    // or the ripple carry out of Block 0 (c_b0_cout_ripple) if Block 0 does not propagate (~P_0).
    assign c_in_b1 = (P_0 & cin) | (~P_0 & c_b0_cout_ripple);

    // Ripple carry within block 1
    assign c_b1_c3 = g[2] | (p[2] & c_in_b1);
    assign c_b1_cout_ripple = g[3] | (p[3] & c_b1_c3);
    // Block 1 propagate signal
    assign P_1 = p[2] & p[3];

    // Final Carry Out (from Block 1)
    // The final carry out is either the carry-in to Block 1 (c_in_b1) if Block 1 propagates (P_1),
    // or the ripple carry out of Block 1 (c_b1_cout_ripple) if Block 1 does not propagate (~P_1).
    assign cout = (P_1 & c_in_b1) | (~P_1 & c_b1_cout_ripple);

    // Sum bits
    assign s[0] = p[0] ^ cin;
    assign s[1] = p[1] ^ c_b0_c1;
    assign s[2] = p[2] ^ c_in_b1;
    assign s[3] = p[3] ^ c_b1_c3;

    // Combine carry and sum for the final output
    assign out_sum = {cout, s[3:0]};

endmodule