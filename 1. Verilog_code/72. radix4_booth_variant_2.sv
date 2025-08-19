//SystemVerilog
// 17-bit Manchester Carry Chain Adder Module
// This module implements the adder logic functionally equivalent to A+B+Cin
// in a way that can be mapped to Manchester Carry Chain cells by synthesis tools.
module manchester_adder_17bit (
    input [16:0] A,
    input [16:0] B,
    input Cin,
    output [16:0] Sum,
    output Cout
);
    wire [16:0] P; // Propagate: A ^ B
    wire [16:0] G; // Generate: A & B
    wire [17:0] C; // Carries

    // Calculate Propagate and Generate signals
    assign P = A ^ B;
    assign G = A & B;

    // Carry chain implementation (Manchester style hint)
    // C[i+1] = G[i] | (P[i] & C[i])
    // Explicitly writing out the chain encourages synthesis to map to dedicated carry logic if available.
    assign C[0] = Cin;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & C[1]);
    assign C[3] = G[2] | (P[2] & C[2]);
    assign C[4] = G[3] | (P[3] & C[3]);
    assign C[5] = G[4] | (P[4] & C[4]);
    assign C[6] = G[5] | (P[5] & C[5]);
    assign C[7] = G[6] | (P[6] & C[6]);
    assign C[8] = G[7] | (P[7] & C[7]);
    assign C[9] = G[8] | (P[8] & C[8]);
    assign C[10] = G[9] | (P[9] & C[9]);
    assign C[11] = G[10] | (P[10] & C[10]);
    assign C[12] = G[11] | (P[11] & C[11]);
    assign C[13] = G[12] | (P[12] & C[12]);
    assign C[14] = G[13] | (P[13] & C[13]);
    assign C[15] = G[14] | (P[14] & C[14]);
    assign C[16] = G[15] | (P[15] & C[15]);
    assign C[17] = G[16] | (P[16] & C[16]);

    // Calculate Sum signals
    // Sum[i] = P[i] ^ C[i]
    assign Sum = P ^ C[16:0];

    // Assign final carry out
    assign Cout = C[17];

endmodule

//SystemVerilog
module radix4_booth (
    input [7:0] X,
    input [7:0] Y,
    output [15:0] Product
);
    // Internal signals
    wire [15:0] result_wire; // Wire for the final result before output assignment
    wire [8:0] Y_extended;

    // Intermediate computation wires
    wire [16:0] A_val_wire;
    wire [16:0] S_val_wire;

    wire [16:0] P0_wire;
    wire [16:0] P1_wire;
    wire [16:0] P2_wire;
    wire [16:0] P3_wire;
    wire [16:0] P4_wire;

    // Wires for adder operands and results
    wire [16:0] add0_operand_B;
    wire [16:0] P0_next_sum; // Output from the first adder

    wire [16:0] add1_operand_B;
    wire [16:0] P1_next_sum; // Output from the second adder

    wire [16:0] add2_operand_B;
    wire [16:0] P2_next_sum; // Output from the third adder

    wire [16:0] add3_operand_B;
    wire [16:0] P3_next_sum; // Output from the fourth adder


    // Extended Y value with padding
    assign Y_extended = {Y, 1'b0};

    // Calculate A and S based on X (combinational)
    assign A_val_wire = {{9{X[7]}}, X, 8'b0}; // A = X shifted left by 8, with sign extension (17 bits)
    wire [8:0] neg_X = (~X) + 1'b1; // 9-bit 2's complement of X
    assign S_val_wire = {neg_X, 8'b0}; // S = -X shifted left by 8 (17 bits)

    // Initial P value (P before iteration 0)
    assign P0_wire = {8'b0, Y_extended}; // 17 bits

    // Iteration 0: Determine operand B using continuous assignment (combinational logic)
    assign add0_operand_B = (P0_wire[2:0] == 3'b001 || P0_wire[2:0] == 3'b010) ? A_val_wire :
                            (P0_wire[2:0] == 3'b011) ? {A_val_wire[15:0], 1'b0} :
                            (P0_wire[2:0] == 3'b100) ? {S_val_wire[15:0], 1'b0} :
                            (P0_wire[2:0] == 3'b101 || P0_wire[2:0] == 3'b110) ? S_val_wire :
                            17'b0; // default for 000, 111

    // Instantiate Manchester Adder for Iteration 0
    manchester_adder_17bit add_stage0 (
        .A(P0_wire),
        .B(add0_operand_B),
        .Cin(1'b0),
        .Sum(P0_next_sum),
        .Cout() // Cout is not used
    );
    // Arithmetic shift right by 2
    assign P1_wire = {{2{P0_next_sum[16]}}, P0_next_sum[16:2]}; // 17 bits

    // Iteration 1: Determine operand B using continuous assignment
    assign add1_operand_B = (P1_wire[2:0] == 3'b001 || P1_wire[2:0] == 3'b010) ? A_val_wire :
                            (P1_wire[2:0] == 3'b011) ? {A_val_wire[15:0], 1'b0} :
                            (P1_wire[2:0] == 3'b100) ? {S_val_wire[15:0], 1'b0} :
                            (P1_wire[2:0] == 3'b101 || P1_wire[2:0] == 3'b110) ? S_val_wire :
                            17'b0; // default

    // Instantiate Manchester Adder for Iteration 1
    manchester_adder_17bit add_stage1 (
        .A(P1_wire),
        .B(add1_operand_B),
        .Cin(1'b0),
        .Sum(P1_next_sum),
        .Cout()
    );
    // Arithmetic shift right by 2
    assign P2_wire = {{2{P1_next_sum[16]}}, P1_next_sum[16:2]}; // 17 bits

    // Iteration 2: Determine operand B using continuous assignment
    assign add2_operand_B = (P2_wire[2:0] == 3'b001 || P2_wire[2:0] == 3'b010) ? A_val_wire :
                            (P2_wire[2:0] == 3'b011) ? {A_val_wire[15:0], 1'b0} :
                            (P2_wire[2:0] == 3'b100) ? {S_val_wire[15:0], 1'b0} :
                            (P2_wire[2:0] == 3'b101 || P2_wire[2:0] == 3'b110) ? S_val_wire :
                            17'b0; // default

    // Instantiate Manchester Adder for Iteration 2
    manchester_adder_17bit add_stage2 (
        .A(P2_wire),
        .B(add2_operand_B),
        .Cin(1'b0),
        .Sum(P2_next_sum),
        .Cout()
    );
    // Arithmetic shift right by 2
    assign P3_wire = {{2{P2_next_sum[16]}}, P2_next_sum[16:2]}; // 17 bits

    // Iteration 3: Determine operand B using continuous assignment
    assign add3_operand_B = (P3_wire[2:0] == 3'b001 || P3_wire[2:0] == 3'b010) ? A_val_wire :
                            (P3_wire[2:0] == 3'b011) ? {A_val_wire[15:0], 1'b0} :
                            (P3_wire[2:0] == 3'b100) ? {S_val_wire[15:0], 1'b0} :
                            (P3_wire[2:0] == 3'b101 || P3_wire[2:0] == 3'b110) ? S_val_wire :
                            17'b0; // default

    // Instantiate Manchester Adder for Iteration 3
    manchester_adder_17bit add_stage3 (
        .A(P3_wire),
        .B(add3_operand_B),
        .Cin(1'b0),
        .Sum(P3_next_sum),
        .Cout()
    );
    // Arithmetic shift right by 2
    assign P4_wire = {{2{P3_next_sum[16]}}, P3_next_sum[16:2]}; // 17 bits

    // Final result is the upper 16 bits of P after 4 shifts (8 bit positions total)
    assign result_wire = P4_wire[16:1];

    // Output assignment
    assign Product = result_wire;

endmodule