// full_adder_1bit module
// Implements the logic for a single bit full adder
module full_adder_1bit (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    // Basic 1-bit full adder logic
    assign {cout, sum} = a + b + cin;
endmodule

// ripple_carry_adder module (Top module)
// This module implements an N-bit ripple-carry adder
// by instantiating N 1-bit full adders.
module ripple_carry_adder #(parameter N=8)(
    input [N-1:0] a,
    input [N-1:0] b,
    input cin,
    output [N-1:0] sum,
    output cout
);

    // Internal wire to connect carries between full adder stages
    // carry[0] is the input carry (cin)
    // carry[i+1] is the carry-out of stage i, which becomes the carry-in of stage i+1
    // carry[N] is the final carry-out (cout)
    wire [N:0] carry;

    // Connect the input carry to the first stage
    assign carry[0] = cin;

    // Connect the carry-out of the last stage to the module's output cout
    assign cout = carry[N];

    // Instantiate N 1-bit full adders in a ripple-carry chain
    // The generate block creates N instances of the full_adder_1bit module
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : adder_stage
            // Instantiate full adder for bit i
            full_adder_1bit fa_inst (
                .a(a[i]),         // Input bit a[i]
                .b(b[i]),         // Input bit b[i]
                .cin(carry[i]),   // Carry-in from previous stage (or initial cin)
                .sum(sum[i]),     // Output sum bit sum[i]
                .cout(carry[i+1]) // Carry-out to next stage
            );
        end
    endgenerate

endmodule