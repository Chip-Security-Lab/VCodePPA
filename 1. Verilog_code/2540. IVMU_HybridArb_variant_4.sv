//SystemVerilog
module IVMU_HybridArb #(parameter MODE=0) (
    input clk,
    input [3:0] req,
    output reg [1:0] grant
);

// Internal signals for Brent-Kung adder path
wire [3:0] grant_padded;
wire [3:0] one_val;
wire [3:0] sum_bk_4bit;
wire cout_bk; // Not used in this logic

// Signal for the incremented value from the adder (combinational)
wire [1:0] incremented_grant_comb;

// Signal for the intended next grant value considering wrap-around (combinational)
wire [1:0] intended_next_grant_comb;

// Pipelined register for the intended next grant value (critical path cut)
reg [1:0] pipelined_next_grant;

// Pad current grant to 4 bits for the 4-bit adder
assign grant_padded = {2'b0, grant};

// Constant 1, padded to 4 bits
assign one_val = 4'd1; // 4'b0001

// Instantiate the 4-bit Brent-Kung adder
// This calculates grant + 1
brent_kung_adder_4bit bk_adder (
    .a(grant_padded),
    .b(one_val),
    .cin(1'b0), // No carry-in for increment by 1
    .sum(sum_bk_4bit),
    .cout(cout_bk) // cout is not used in this specific logic
);

// Get the incremented value from the adder (lower 2 bits)
assign incremented_grant_comb = sum_bk_4bit[1:0];

// Calculate the intended next grant value combinatorially based on current grant
// If current grant is 3, next is 0 (wrap-around)
// Otherwise, next is the incremented value from the adder
assign intended_next_grant_comb = (grant == 2'b11) ? 2'b0 : incremented_grant_comb;

// Pipeline stage: Register the intended next grant value
// This breaks the combinational path from 'grant' through the adder and wrap-around logic
always @(posedge clk) begin
    pipelined_next_grant <= intended_next_grant_comb;
end

// Sequential logic for grant update
// This stage uses the pipelined value for the round-robin mode
always @(posedge clk) begin
    if (MODE == 1) begin // Fixed mode (assuming MODE 1 is fixed based on original ternary)
        // This logic does not depend on the adder output or previous grant value
        if (req[0]) grant <= 2'b0;
        else if (req[1]) grant <= 2'b1;
        else grant <= 2'b10; // Default grant 2 if req[0] and req[1] are low
    end else begin // MODE == 0 (Round-robin)
        // Update grant with the pipelined intended next value
        // The decision (wrap-around vs increment) was made one cycle ago
        grant <= pipelined_next_grant;
    end
end

endmodule

// Brent-Kung Adder 4-bit module (kept as is, it's combinational logic)
module brent_kung_adder_4bit (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);

// Level 0: Generate and Propagate signals for each bit
wire [3:0] p; // Propagate
wire [3:0] g; // Generate

assign p = a ^ b;
assign g = a & b;

// Level 1: Prefix combinations (pairs)
wire g1_0, p1_0; // Prefix G/P for bits [1:0]
wire g3_2, p3_2; // Prefix G/P for bits [3:2]

// combine( (gi, pi), (gj, pj) ) = (gi | (pi & gj), pi & pj)
assign g1_0 = g[1] | (p[1] & g[0]);
assign p1_0 = p[1] & p[0];

assign g3_2 = g[3] | (p[3] & g[2]);
assign p3_2 = p[3] & p[2];

// Level 2: Prefix combinations (groups of 4)
wire g2_0, p2_0; // Prefix G/P for bits [2:0] (combine(g[2], p[2], G1_0, P1_0))
wire g3_0, p3_0; // Prefix G/P for bits [3:0] (combine(G3_2, P3_2, G1_0, P1_0))

assign g2_0 = g[2] | (p[2] & g1_0);
assign p2_0 = p[2] & p1_0; // p[2] & (p[1] & p[0])

assign g3_0 = g3_2 | (p3_2 & g1_0);
assign p3_0 = p3_2 & p1_0; // (p[3] & p[2]) & (p[1] & p[0])

// Carries (using prefix results)
wire c1, c2, c3;
wire c0 = cin; // Carry into bit 0

// c[i] = G_i-1:0 | (P_i-1:0 & cin)
assign c1 = g[0] | (p[0] & c0); // G0:0 = g[0], P0:0 = p[0]
assign c2 = g1_0 | (p1_0 & c0); // G1:0 = g1_0, P1:0 = p1_0
assign c3 = g2_0 | (p2_0 & c0); // G2:0 = g2_0, P2:0 = p2_0
assign cout = g3_0 | (p3_0 & c0); // G3:0 = g3_0, P3:0 = p3_0 (cout is c4)

// Sum calculation
assign sum[0] = p[0] ^ c0;
assign sum[1] = p[1] ^ c1;
assign sum[2] = p[2] ^ c2;
assign sum[3] = p[3] ^ c3;

endmodule