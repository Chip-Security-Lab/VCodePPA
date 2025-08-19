//SystemVerilog
// full_adder submodule
module full_adder (
    input wire i_a,     // First input bit
    input wire i_b,     // Second input bit
    input wire i_cin,   // Carry-in bit
    output wire o_sum,  // Sum output bit
    output wire o_cout  // Carry-out bit
);
    // Function: Implements a single-bit full adder
    // Computes sum = a ^ b ^ cin
    // Computes cout = (a & b) | (cin & (a ^ b))

    assign o_sum = i_a ^ i_b ^ i_cin;
    assign o_cout = (i_a & i_b) | (i_cin & (i_a ^ i_b)); // Alternative: (i_a & i_b) | (i_cin & i_a) | (i_cin & i_b);

endmodule

// Top-level module: Hierarchical 3-bit bitwise adder
module bitwise_add(
    input wire [2:0] a,     // First 3-bit input operand
    input wire [2:0] b,     // Second 3-bit input operand
    output wire [3:0] total // 4-bit sum output (includes carry-out)
);
    // Function: 3-bit ripple-carry adder using full_adder submodules
    // Adds two 3-bit inputs 'a' and 'b' to produce a 4-bit sum 'total'.
    // total[3] is the final carry-out, total[2:0] is the 3-bit sum.

    wire c_out_fa0; // Carry out from the least significant bit full adder (bit 0)
    wire c_out_fa1; // Carry out from the middle bit full adder (bit 1)
    // c_out_fa2 is directly connected to total[3]

    // Instantiate full adder for bit 0 (LSB)
    // Inputs: a[0], b[0], carry-in = 0
    // Outputs: total[0], c_out_fa0
    full_adder fa_bit0 (
        .i_a(a[0]),
        .i_b(b[0]),
        .i_cin(1'b0), // LSB stage has a carry-in of 0
        .o_sum(total[0]),
        .o_cout(c_out_fa0)
    );

    // Instantiate full adder for bit 1
    // Inputs: a[1], b[1], carry-in = c_out_fa0
    // Outputs: total[1], c_out_fa1
    full_adder fa_bit1 (
        .i_a(a[1]),
        .i_b(b[1]),
        .i_cin(c_out_fa0), // Carry-in is the carry-out from the previous stage (bit 0)
        .o_sum(total[1]),
        .o_cout(c_out_fa1)
    );

    // Instantiate full adder for bit 2 (MSB)
    // Inputs: a[2], b[2], carry-in = c_out_fa1
    // Outputs: total[2], total[3] (final carry-out)
    full_adder fa_bit2 (
        .i_a(a[2]),
        .i_b(b[2]),
        .i_cin(c_out_fa1), // Carry-in is the carry-out from the previous stage (bit 1)
        .o_sum(total[2]),
        .o_cout(total[3]) // The carry-out from the MSB stage is the most significant bit of the total sum
    );

endmodule