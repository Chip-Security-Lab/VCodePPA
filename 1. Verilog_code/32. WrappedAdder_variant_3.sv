//SystemVerilog
module Adder_10(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Width parameter (optional, but good practice)
    localparam DATA_WIDTH = 4;

    // Generate and Propagate signals for each bit position
    wire [DATA_WIDTH-1:0] p; // Propagate: A ^ B
    wire [DATA_WIDTH-1:0] g; // Generate: A & B

    assign p = A ^ B;
    assign g = A & B;

    // Input carry (implicitly 0 for A+B sum)
    wire c_in = 1'b0;

    // Carry Lookahead Logic for 4 bits
    // c[i+1] = g[i] | (p[i] & c[i])
    // Expanding for parallel calculation (with c_in = c[0]):
    // c1 = g[0] | (p[0] & c_in)
    // c2 = g[1] | (p[1] & c1) = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c_in)
    // c3 = g[2] | (p[2] & c2) = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c_in)
    // c4 = g[3] | (p[3] & c3) = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c_in)

    // Since c_in is 0 in this specific module (A+B operation):
    wire c1, c2, c3, c4; // Carries c1 through c4

    assign c1 = g[0];
    assign c2 = g[1] | (p[1] & g[0]);
    assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);


    // Calculate sum bits
    // s[i] = p[i] ^ c[i]
    // s0 = p[0] ^ c_in
    // s1 = p[1] ^ c1
    // s2 = p[2] ^ c2
    // s3 = p[3] ^ c3
    wire [DATA_WIDTH-1:0] s;
    assign s[0] = p[0] ^ c_in; // Equivalent to p[0] ^ 0
    assign s[1] = p[1] ^ c1;
    assign s[2] = p[2] ^ c2;
    assign s[3] = p[3] ^ c3;

    // Output sum = {carry_out, s[3:0]}
    assign sum = {c4, s[3:0]};

endmodule