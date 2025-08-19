//SystemVerilog
// Top-level module - 4-bit Carry Lookahead Adder
module nand2_9 (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [3:0] Y
);
    // Internal signals for carry lookahead adder
    wire [3:0] P, G;    // Propagate and Generate signals
    wire [4:0] C;       // Carry signals (including Cin and Cout)
    
    // Generate the P and G signals
    assign P = A ^ B;   // Propagate = A XOR B
    assign G = A & B;   // Generate = A AND B
    
    // Carry lookahead logic
    assign C[0] = 1'b0; // No carry-in for LSB
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C[0]);
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C[0]);
    
    // Sum calculation
    assign Y = P ^ C[3:0];
endmodule