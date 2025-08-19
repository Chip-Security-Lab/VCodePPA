//SystemVerilog
module carry_lookahead_adder_8bit_pipelined (
    input logic [7:0] a,
    input logic [7:0] b,
    input logic       cin,
    input logic       clk,
    input logic       rst_n, // Active low reset
    output logic [7:0] sum,
    output logic      cout
);

//------------------------------------------------------------------------------
// Pipeline Stage 1: Input Registration and Bit-level P/G Calculation
// Inputs: a, b, cin
// Outputs: s1_bit_p, s1_bit_g, s1_cin (registered)
//------------------------------------------------------------------------------
logic [7:0] s1_bit_p; // Registered bit-level Propagate signals
logic [7:0] s1_bit_g; // Registered bit-level Generate signals
logic       s1_cin;   // Registered carry-in

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s1_bit_p <= '0;
        s1_bit_g <= '0;
        s1_cin   <= '0;
    end else begin
        // Combinational calculation of bit P/G happens here
        s1_bit_p <= a ^ b;
        s1_bit_g <= a & b;
        // Register the input carry-in
        s1_cin   <= cin;
    end
end

//------------------------------------------------------------------------------
// Pipeline Stage 2: Carry Lookahead and Sum Generation
// Inputs: s1_bit_p, s1_bit_g, s1_cin (from Stage 1 registers)
// Outputs: s2_sum, s2_cout (registered)
//------------------------------------------------------------------------------
logic [8:0] s2_carries; // Intermediate carries calculated in Stage 2
logic [7:0] s2_sum_comb; // Combinational sum output of Stage 2
logic       s2_cout_comb; // Combinational cout output of Stage 2

// Intermediate signals for Group Propagate and Generate (within Stage 2 combinational logic)
// Using registered bit P/G from Stage 1
logic s2_group0_p; // Group 0 Propagate (bits 0-3)
logic s2_group0_g; // Group 0 Generate (bits 0-3)
logic s2_group1_p; // Group 1 Propagate (bits 4-7)
logic s2_group1_g; // Group 1 Generate (bits 4-7)

// Calculate Group 0 P and G
assign s2_group0_p = s1_bit_p[3] & s1_bit_p[2] & s1_bit_p[1] & s1_bit_p[0];
assign s2_group0_g = s1_bit_g[3] | (s1_bit_p[3] & s1_bit_g[2]) | (s1_bit_p[3] & s1_bit_p[2] & s1_bit_g[1]) | (s1_bit_p[3] & s1_bit_p[2] & s1_bit_p[1] & s1_bit_g[0]);

// Calculate Group 1 P and G
assign s2_group1_p = s1_bit_p[7] & s1_bit_p[6] & s1_bit_p[5] & s1_bit_p[4];
assign s2_group1_g = s1_bit_g[7] | (s1_bit_p[7] & s1_bit_g[6]) | (s1_bit_p[7] & s1_bit_p[6] & s1_bit_g[5]) | (s1_bit_p[7] & s1_bit_p[6] & s1_bit_p[5] & s1_bit_g[4]);

// Calculate carries based on registered P/G and cin (s1_cin)
// s2_carries[i] is carry-in to bit i
assign s2_carries[0] = s1_cin; // Registered carry-in from Stage 1

// Carries within Group 0 (bits 0-3) based on s2_carries[0]
assign s2_carries[1] = s1_bit_g[0] | (s1_bit_p[0] & s2_carries[0]);
assign s2_carries[2] = s1_bit_g[1] | (s1_bit_p[1] & s2_carries[1]);
assign s2_carries[3] = s1_bit_g[2] | (s1_bit_p[2] & s2_carries[2]);

// Carry out of Group 0 (carry into bit 4) based on s2_carries[0]
// This is the group carry C[1] = GG[0] | (GP[0] & C[0])
assign s2_carries[4] = s2_group0_g | (s2_group0_p & s2_carries[0]);

// Carries within Group 1 (bits 4-7) based on s2_carries[4]
assign s2_carries[5] = s1_bit_g[4] | (s1_bit_p[4] & s2_carries[4]);
assign s2_carries[6] = s1_bit_g[5] | (s1_bit_p[5] & s2_carries[5]);
assign s2_carries[7] = s1_bit_g[6] | (s1_bit_p[6] & s2_carries[6]);

// Carry out of Group 1 (carry into bit 8), which is the module cout, based on s2_carries[4]
// This is the group carry C[2] = GG[1] | (GP[1] & C[1])
assign s2_carries[8] = s2_group1_g | (s2_group1_p & s2_carries[4]);

// Calculate sum bits based on registered P and calculated carries
assign s2_sum_comb[0] = s1_bit_p[0] ^ s2_carries[0];
assign s2_sum_comb[1] = s1_bit_p[1] ^ s2_carries[1];
assign s2_sum_comb[2] = s1_bit_p[2] ^ s2_carries[2];
assign s2_sum_comb[3] = s1_bit_p[3] ^ s2_carries[3];
assign s2_sum_comb[4] = s1_bit_p[4] ^ s2_carries[4];
assign s2_sum_comb[5] = s1_bit_p[5] ^ s2_carries[5];
assign s2_sum_comb[6] = s1_bit_p[6] ^ s2_carries[6];
assign s2_sum_comb[7] = s1_bit_p[7] ^ s2_carries[7];

// The final carry-out is the last calculated carry
assign s2_cout_comb = s2_carries[8];

// Register Stage 2 outputs
logic [7:0] s2_sum_reg;
logic       s2_cout_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s2_sum_reg <= '0;
        s2_cout_reg <= '0;
    end else begin
        s2_sum_reg <= s2_sum_comb; // Register the calculated sum
        s2_cout_reg <= s2_cout_comb; // Register the calculated cout
    end
end

//------------------------------------------------------------------------------
// Final Outputs
// Outputs are the registered results from Stage 2
//------------------------------------------------------------------------------
assign sum = s2_sum_reg;
assign cout = s2_cout_reg;

endmodule