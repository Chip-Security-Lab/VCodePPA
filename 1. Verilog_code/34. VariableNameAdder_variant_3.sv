//SystemVerilog
// SystemVerilog
// Pipelined 8-bit Brent-Kung Adder
// Stages:
// 1. P/G Generation + Register (Latency 1)
// 2. Prefix Network Levels 1-3 + Register (Latency 2)
// 3. Carry Computation + Register (Latency 3)
// 4. Sum Computation + Output Register (Latency 4)
module brent_kung_adder_8bit_pipelined (
    input wire             clk,     // Clock
    input wire             rst_n,   // Asynchronous reset (active low)
    input wire [7:0]       A,       // First operand
    input wire [7:0]       B,       // Second operand
    input wire             cin,     // Carry-in
    output logic [7:0]     S,       // Sum output
    output logic           cout     // Carry-out
);

//------------------------------------------------------------------------------
// Stage 1: P/G Generation and Register (Latency 1)
// Computes initial propagate (p) and generate (g) signals for each bit.
// Registers p, g, and cin for the next stage.
//------------------------------------------------------------------------------
wire [7:0] p_w; // Propagate wire
wire [7:0] g_w; // Generate wire

assign p_w = A ^ B;
assign g_w = A & B;

logic [7:0] p_s1, g_s1; // Registered P/G signals (Stage 1 output)
logic       cin_s1;     // Registered carry-in (Stage 1 output)

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_s1 <= '0;
        g_s1 <= '0;
        cin_s1 <= '0;
    end else begin
        p_s1 <= p_w;
        g_s1 <= g_w;
        cin_s1 <= cin;
    end
end

//------------------------------------------------------------------------------
// Stage 2: Prefix Network Levels 1-3 and Register (Latency 2)
// Computes intermediate group propagate (Pp) and group generate (Gp) signals
// using the Brent-Kung structure based on Stage 1 registered outputs.
// Registers these intermediate signals for the next stage.
//------------------------------------------------------------------------------
// Level 1 (distance 1) - Black cells (Ranges [1:0], [3:2], [5:4], [7:6])
wire Gp1_1_w, Pp1_1_w; // Range [1:0]
wire Gp1_3_w, Pp1_3_w; // Range [3:2]
wire Gp1_5_w, Pp1_5_w; // Range [5:4]
wire Gp1_7_w, Pp1_7_w; // Range [7:6]

assign Gp1_1_w = g_s1[1] | (p_s1[1] & g_s1[0]); assign Pp1_1_w = p_s1[1] & p_s1[0];
assign Gp1_3_w = g_s1[3] | (p_s1[3] & g_s1[2]); assign Pp1_3_w = p_s1[3] & p_s1[2];
assign Gp1_5_w = g_s1[5] | (p_s1[5] & g_s1[4]); assign Pp1_5_w = p_s1[5] & p_s1[4];
assign Gp1_7_w = g_s1[7] | (p_s1[7] & g_s1[6]); assign Pp1_7_w = p_s1[7] & p_s1[6];

// Level 2 (distance 2) - Black cells (Ranges [3:0], [7:4])
wire Gp2_3_w, Pp2_3_w; // Range [3:0]
wire Gp2_7_w, Pp2_7_w; // Range [7:4]

assign Gp2_3_w = Gp1_3_w | (Pp1_3_w & Gp1_1_w); assign Pp2_3_w = Pp1_3_w & Pp1_1_w;
assign Gp2_7_w = Gp1_7_w | (Pp1_7_w & Gp1_5_w); assign Pp2_7_w = Pp1_7_w & Pp1_5_w;

// Level 3 (distance 4) - Black cell (Range [7:0])
wire Gp3_7_w, Pp3_7_w; // Range [7:0]

assign Gp3_7_w = Gp2_7_w | (Pp2_7_w & Gp2_3_w); assign Pp3_7_w = Pp2_7_w & Pp2_3_w;

// Registered Prefix outputs (Stage 2 output)
logic Gp1_1_s2, Pp1_1_s2;
logic Gp1_3_s2, Pp1_3_s2;
logic Gp1_5_s2, Pp1_5_s2;
logic Gp1_7_s2, Pp1_7_s2;
logic Gp2_3_s2, Pp2_3_s2;
logic Gp2_7_s2, Pp2_7_s2;
logic Gp3_7_s2, Pp3_7_s2;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Gp1_1_s2 <= '0; Pp1_1_s2 <= '0;
        Gp1_3_s2 <= '0; Pp1_3_s2 <= '0;
        Gp1_5_s2 <= '0; Pp1_5_s2 <= '0;
        Gp1_7_s2 <= '0; Pp1_7_s2 <= '0;
        Gp2_3_s2 <= '0; Pp2_3_s2 <= '0;
        Gp2_7_s2 <= '0; Pp2_7_s2 <= '0;
        Gp3_7_s2 <= '0; Pp3_7_s2 <= '0;
    end else begin
        Gp1_1_s2 <= Gp1_1_w; Pp1_1_s2 <= Pp1_1_w;
        Gp1_3_s2 <= Gp1_3_w; Pp1_3_s2 <= Pp1_3_w;
        Gp1_5_s2 <= Gp1_5_w; Pp1_5_s2 <= Pp1_5_w;
        Gp1_7_s2 <= Gp1_7_w; Pp1_7_s2 <= Pp1_7_w;
        Gp2_3_s2 <= Gp2_3_w; Pp2_3_s2 <= Pp2_3_w;
        Gp2_7_s2 <= Gp2_7_w; Pp2_7_s2 <= Pp2_7_w;
        Gp3_7_s2 <= Gp3_7_w; Pp3_7_s2 <= Pp3_7_w;
    end
end

//------------------------------------------------------------------------------
// Stage 3: Carry Computation and Register (Latency 3)
// Computes all carries C[1]..C[8] using registered P/G, cin, and prefix outputs.
// Registers carries for the next stage.
//------------------------------------------------------------------------------
wire [8:0] carry_w; // Wires for combinational carries

// C[i] is carry-in to bit i. C[0] = cin_s1.
assign carry_w[0] = cin_s1;
assign carry_w[1] = g_s1[0] | (p_s1[0] & carry_w[0]); // C[1] = G[0:0] | (P[0:0] & cin_s1)
assign carry_w[2] = Gp1_1_s2 | (Pp1_1_s2 & carry_w[0]); // C[2] = G[1:0] | (P[1:0] & cin_s1)
assign carry_w[3] = g_s1[2] | (p_s1[2] & carry_w[2]); // C[3] = g[2] | (p[2] & C[2])
assign carry_w[4] = Gp2_3_s2 | (Pp2_3_s2 & carry_w[0]); // C[4] = G[3:0] | (P[3:0] & cin_s1)
assign carry_w[5] = g_s1[4] | (p_s1[4] & carry_w[4]); // C[5] = g[4] | (p[4] & C[4])
assign carry_w[6] = Gp1_5_s2 | (Pp1_5_s2 & carry_w[4]); // C[6] = G[5:4] | (P[5:4] & C[4])
assign carry_w[7] = g_s1[6] | (p_s1[6] & carry_w[6]); // C[7] = g[6] | (p[6] & C[6])
assign carry_w[8] = Gp3_7_s2 | (Pp3_7_s2 & carry_w[0]); // C[8] = G[7:0] | (P[7:0] & cin_s1) = cout

logic [8:0] carry_s3; // Registered carries (Stage 3 output)

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        carry_s3 <= '0;
    end else begin
        carry_s3 <= carry_w;
    end
end

//------------------------------------------------------------------------------
// Stage 4: Sum Computation and Output Register (Latency 4)
// Computes the final sum bits and carry-out using registered P/G and carries.
// Registers sum and carry-out as final outputs.
//------------------------------------------------------------------------------
wire [7:0] S_w; // Wire for combinational sum
wire cout_w;    // Wire for combinational carry-out

// Sum computation: S[i] = P[i] ^ C[i]
assign S_w[0] = p_s1[0] ^ carry_s3[0];
assign S_w[1] = p_s1[1] ^ carry_s3[1];
assign S_w[2] = p_s1[2] ^ carry_s3[2];
assign S_w[3] = p_s1[3] ^ carry_s3[3];
assign S_w[4] = p_s1[4] ^ carry_s3[4];
assign S_w[5] = p_s1[5] ^ carry_s3[5];
assign S_w[6] = p_s1[6] ^ carry_s3[6];
assign S_w[7] = p_s1[7] ^ carry_s3[7];

// Carry-out is the most significant carry
assign cout_w = carry_s3[8];

// Output Registers (Stage 4 output)
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        S <= '0;
        cout <= '0;
    end else begin
        S <= S_w;
        cout <= cout_w;
    end
end

endmodule