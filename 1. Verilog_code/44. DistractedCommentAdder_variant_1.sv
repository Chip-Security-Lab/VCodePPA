//SystemVerilog
// Brent-Kung Adder 8-bit - Pipelined (2 Stages)

module brent_kung_adder_8bit_pipelined (
    input logic [7:0] a,
    input logic [7:0] b,
    input logic       cin,
    input logic       clk,
    input logic       rst_n, // Active low reset
    output logic [7:0] sum,
    output logic      cout
);

// --- Stage 1: P/G Generation (Bit-level to Level 2) and Registering ---

// Stage 1 Combinational Logic (Compute P/G up to Level 2)
logic [7:0] p_s1_comb; // Propagate: a[i] ^ b[i]
logic [7:0] g_s1_comb; // Generate: a[i] & b[i]
logic [3:0] gp_l1_g_s1_comb; // Generate for blocks of size 2 (Level 1)
logic [3:0] gp_l1_p_s1_comb; // Propagate for blocks of size 2 (Level 1)
logic [1:0] gp_l2_g_s1_comb; // Generate for blocks of size 4 (Level 2)
logic [1:0] gp_l2_p_s1_comb; // Propagate for blocks of size 4 (Level 2)

// Level 0 P/G
assign p_s1_comb = a ^ b;
assign g_s1_comb = a & b;

// Level 1 P/G (pairs)
assign gp_l1_g_s1_comb[0] = g_s1_comb[1] | (p_s1_comb[1] & g_s1_comb[0]); assign gp_l1_p_s1_comb[0] = p_s1_comb[1] & p_s1_comb[0]; // bits 0-1
assign gp_l1_g_s1_comb[1] = g_s1_comb[3] | (p_s1_comb[3] & g_s1_comb[2]); assign gp_l1_p_s1_comb[1] = p_s1_comb[3] & p_s1_comb[2]; // bits 2-3
assign gp_l1_g_s1_comb[2] = g_s1_comb[5] | (p_s1_comb[5] & g_s1_comb[4]); assign gp_l1_p_s1_comb[2] = p_s1_comb[5] & p_s1_comb[4]; // bits 4-5
assign gp_l1_g_s1_comb[3] = g_s1_comb[7] | (p_s1_comb[7] & g_s1_comb[6]); assign gp_l1_p_s1_comb[3] = p_s1_comb[7] & p_s1_comb[6]; // bits 6-7

// Level 2 P/G (quads)
assign gp_l2_g_s1_comb[0] = gp_l1_g_s1_comb[1] | (gp_l1_p_s1_comb[1] & gp_l1_g_s1_comb[0]); assign gp_l2_p_s1_comb[0] = gp_l1_p_s1_comb[1] & gp_l1_p_s1_comb[0]; // bits 0-3
assign gp_l2_g_s1_comb[1] = gp_l1_g_s1_comb[3] | (gp_l1_p_s1_comb[3] & gp_l1_g_s1_comb[2]); assign gp_l2_p_s1_comb[1] = gp_l1_p_s1_comb[3] & gp_l1_p_s1_comb[2]; // bits 4-7


// Stage 1 Registers (Pipeline Register 1)
logic [7:0] p_s1_reg;
logic [7:0] g_s1_reg;
logic [3:0] gp_l1_g_s1_reg;
logic [3:0] gp_l1_p_s1_reg;
logic [1:0] gp_l2_g_s1_reg;
logic [1:0] gp_l2_p_s1_reg;
logic       cin_s1_reg; // Registering cin as well

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_s1_reg       <= '0;
        g_s1_reg       <= '0;
        gp_l1_g_s1_reg <= '0;
        gp_l1_p_s1_reg <= '0;
        gp_l2_g_s1_reg <= '0;
        gp_l2_p_s1_reg <= '0;
        cin_s1_reg     <= '0;
    end else begin
        p_s1_reg       <= p_s1_comb;
        g_s1_reg       <= g_s1_comb;
        gp_l1_g_s1_reg <= gp_l1_g_s1_comb;
        gp_l1_p_s1_reg <= gp_l1_p_s1_comb;
        gp_l2_g_s1_reg <= gp_l2_g_s1_comb;
        gp_l2_p_s1_reg <= gp_l2_p_s1_comb;
        cin_s1_reg     <= cin;
    end
end

// Signals for Stage 2 (read from Stage 1 Registers)
logic [7:0] p_s2;
logic [7:0] g_s2;
logic [3:0] gp_l1_g_s2;
logic [3:0] gp_l1_p_s2;
logic [1:0] gp_l2_g_s2;
logic [1:0] gp_l2_p_s2;
logic       cin_s2;

assign p_s2       = p_s1_reg;
assign g_s2       = g_s1_reg;
assign gp_l1_g_s2 = gp_l1_g_s1_reg;
assign gp_l1_p_s2 = gp_l1_p_s1_reg;
assign gp_l2_g_s2 = gp_l2_g_s1_reg;
assign gp_l2_p_s2 = gp_l2_p_s1_reg;
assign cin_s2     = cin_s1_reg;


// --- Stage 2: Prefix Tree (Level 3), Carry Generation, Sum/Cout and Registering ---

// Stage 2 Combinational Logic (Compute Level 3 P/G, Carries, Sum, Cout)

// Brent-Kung Prefix Tree (Reduction Phase) - using Stage 2 inputs
// Level 3 (oct)
logic gp_l3_g_s2_comb; // Generate for block of size 8
logic gp_l3_p_s2_comb; // Propagate for block of size 8
assign gp_l3_g_s2_comb = gp_l2_g_s2[1] | (gp_l2_p_s2[1] & gp_l2_g_s2[0]); assign gp_l3_p_s2_comb = gp_l2_p_s2[1] & gp_l2_p_s2[0]; // bits 0-7

// Carry Generation Tree (Expansion Phase) - using Stage 2 inputs
// c[i] is the carry into bit i. c[0] is cin_s2. c[8] is cout.
logic [8:0] c_s2_comb;
assign c_s2_comb[0] = cin_s2;

// Level 2 carries (combine with level 2 G/P)
assign c_s2_comb[4] = gp_l2_g_s2[0] | (gp_l2_p_s2[0] & c_s2_comb[0]); // Carry into bit 4 (G_0:3 | P_0:3 & cin_s2)

// Level 1 carries (combine with level 1 G/P)
assign c_s2_comb[2] = gp_l1_g_s2[0] | (gp_l1_p_s2[0] & c_s2_comb[0]); // Carry into bit 2 (G_0:1 | P_0:1 & cin_s2)
assign c_s2_comb[6] = gp_l1_g_s2[2] | (gp_l1_p_s2[2] & c_s2_comb[4]); // Carry into bit 6 (G_4:5 | P_4:5 & c[4])

// Level 0 carries (combine with level 0 G/P)
assign c_s2_comb[1] = g_s2[0] | (p_s2[0] & c_s2_comb[0]); // Carry into bit 1
assign c_s2_comb[3] = g_s2[2] | (p_s2[2] & c_s2_comb[2]); // Carry into bit 3
assign c_s2_comb[5] = g_s2[4] | (p_s2[4] & c_s2_comb[4]); // Carry into bit 5
assign c_s2_comb[7] = g_s2[6] | (p_s2[6] & c_s2_comb[6]); // Carry into bit 7

// Final Sum and Carry Out Combinational
logic [7:0] sum_s2_comb;
logic       cout_s2_comb;

assign sum_s2_comb[0] = p_s2[0] ^ c_s2_comb[0];
assign sum_s2_comb[1] = p_s2[1] ^ c_s2_comb[1];
assign sum_s2_comb[2] = p_s2[2] ^ c_s2_comb[2];
assign sum_s2_comb[3] = p_s2[3] ^ c_s2_comb[3];
assign sum_s2_comb[4] = p_s2[4] ^ c_s2_comb[4];
assign sum_s2_comb[5] = p_s2[5] ^ c_s2_comb[5];
assign sum_s2_comb[6] = p_s2[6] ^ c_s2_comb[6];
assign sum_s2_comb[7] = p_s2[7] ^ c_s2_comb[7];

assign cout_s2_comb = gp_l3_g_s2_comb | (gp_l3_p_s2_comb & c_s2_comb[0]); // Carry out (G_0:7 | P_0:7 & cin_s2)


// Stage 2 Registers (Pipeline Register 2 - Final Outputs)
logic [7:0] sum_s2_reg;
logic       cout_s2_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum_s2_reg  <= '0;
        cout_s2_reg <= '0;
    end else begin
        sum_s2_reg  <= sum_s2_comb;
        cout_s2_reg <= cout_s2_comb;
    end
end

// Assign final registered outputs to module outputs
assign sum = sum_s2_reg;
assign cout = cout_s2_reg;

endmodule