//SystemVerilog
// SystemVerilog
// Pipelined 8-bit Han-Carlson Adder
// 4-stage pipeline (Input Reg -> Stage 1 -> Stage 2 -> Stage 3 -> Output Reg)
// Restructured data path using reusable cells.
module adder_8_pipelined (
    input wire clk,
    input wire rst,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum,
    output wire cout
);

  // Stage 0: Input Registers
  reg [7:0] a_r0, b_r0;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      a_r0 <= 8'b0;
      b_r0 <= 8'b0;
    end else begin
      a_r0 <= a;
      b_r0 <= b;
    end
  end

  // Stage 1: P/G and Level 1 Prefix Tree Calculation
  wire [7:0] p_comb1; // Propagate: p[i] = a_r0[i] ^ b_r0[i]
  wire [7:0] g_comb1; // Generate: g[i] = a_r0[i] & b_r0[i]
  wire [7:0] GP_l1_comb1; // Level 1 Generate results (indices 1, 3, 5, 7 valid)
  wire [7:0] PP_l1_comb1; // Level 1 Propagate results (indices 1, 3, 5, 7 valid)

  // Initial P/G
  assign p_comb1 = a_r0 ^ b_r0;
  assign g_comb1 = a_r0 & b_r0;

  // Level 1 Black Cells (Span 2)
  // (g[i], p[i]) . (g[i-1], p[i-1]) -> results at index i
  black_cell bc_l1_1 (
    .G1(g_comb1[1]), .P1(p_comb1[1]),
    .G0(g_comb1[0]), .P0(p_comb1[0]),
    .G_out(GP_l1_comb1[1]), .P_out(PP_l1_comb1[1])
  );
  black_cell bc_l1_3 (
    .G1(g_comb1[3]), .P1(p_comb1[3]),
    .G0(g_comb1[2]), .P0(p_comb1[2]),
    .G_out(GP_l1_comb1[3]), .P_out(PP_l1_comb1[3])
  );
  black_cell bc_l1_5 (
    .G1(g_comb1[5]), .P1(p_comb1[5]),
    .G0(g_comb1[4]), .P0(p_comb1[4]),
    .G_out(GP_l1_comb1[5]), .P_out(PP_l1_comb1[5])
  );
  black_cell bc_l1_7 (
    .G1(g_comb1[7]), .P1(p_comb1[7]),
    .G0(g_comb1[6]), .P0(p_comb1[6]),
    .G_out(GP_l1_comb1[7]), .P_out(PP_l1_comb1[7])
  );

  // Stage 1 Registers
  reg [7:0] p_r1, g_r1;
  reg [7:0] GP_l1_r1, PP_l1_r1; // Only bits 1, 3, 5, 7 are meaningful
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      p_r1 <= 8'b0; g_r1 <= 8'b0;
      GP_l1_r1 <= 8'b0; PP_l1_r1 <= 8'b0;
    end else begin
      p_r1 <= p_comb1;
      g_r1 <= g_comb1;
      GP_l1_r1 <= GP_l1_comb1;
      PP_l1_r1 <= PP_l1_comb1;
    end
  end

  // Stage 2: Level 2 and Level 3 Prefix Tree Calculation
  wire [7:0] GP_l2_comb2; // Level 2 Generate results (indices 3, 7 valid)
  wire [7:0] PP_l2_comb2; // Level 2 Propagate results (indices 3, 7 valid)
  wire [7:0] GP_l3_comb2; // Level 3 Generate result (index 7 valid)
  wire [7:0] PP_l3_comb2; // Level 3 Propagate result (index 7 valid)

  // Level 2 Black Cells (Span 4)
  // (GP_l1_r1[i], PP_l1_r1[i]) . (GP_l1_r1[i-2], PP_l1_r1[i-2])
  black_cell bc_l2_3 (
    .G1(GP_l1_r1[3]), .P1(PP_l1_r1[3]),
    .G0(GP_l1_r1[1]), .P0(PP_l1_r1[1]),
    .G_out(GP_l2_comb2[3]), .P_out(PP_l2_comb2[3])
  );
  black_cell bc_l2_7 (
    .G1(GP_l1_r1[7]), .P1(PP_l1_r1[7]),
    .G0(GP_l1_r1[5]), .P0(PP_l1_r1[5]),
    .G_out(GP_l2_comb2[7]), .P_out(PP_l2_comb2[7])
  );

  // Level 3 Black Cell (Span 8)
  // (GP_l2_comb2[7], PP_l2_comb2[7]) . (GP_l2_comb2[3], PP_l2_comb2[3])
  black_cell bc_l3_7 (
    .G1(GP_l2_comb2[7]), .P1(PP_l2_comb2[7]),
    .G0(GP_l2_comb2[3]), .P0(PP_l2_comb2[3]),
    .G_out(GP_l3_comb2[7]), .P_out(PP_l3_comb2[7])
  );

  // Stage 2 Registers
  reg [7:0] GP_l2_r2, PP_l2_r2; // Only bits 3, 7 are meaningful
  reg [7:0] GP_l3_r2, PP_l3_r2; // Only bit 7 is meaningful
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      GP_l2_r2 <= 8'b0; PP_l2_r2 <= 8'b0;
      GP_l3_r2 <= 8'b0; PP_l3_r2 <= 8'b0;
    end else begin
      GP_l2_r2 <= GP_l2_comb2;
      PP_l2_r2 <= PP_l2_comb2;
      GP_l3_r2 <= GP_l3_comb2;
      PP_l3_r2 <= PP_l3_comb2;
    end
  end

  // Stage 3: Carry Generation and Sum Calculation
  wire [8:0] c_comb3; // Carries, c[i] is carry into bit i
  wire [7:0] sum_comb3; // Sum

  // Carry Generation
  assign c_comb3[0] = 1'b0; // Carry-in is 0

  // Carries derived directly from registered block G results (Black Cells)
  assign c_comb3[2] = GP_l1_r1[1]; // Carry into bit 2 = G(0..1)
  assign c_comb3[4] = GP_l2_r2[3]; // Carry into bit 4 = G(0..3)
  assign c_comb3[8] = GP_l3_r2[7]; // Carry out = G(0..7)

  // Intermediate carries derived using registered P/G and block results/carries (Gray Cells)
  gray_cell gc_3_1 ( .G(g_r1[0]), .P(p_r1[0]), .c_in(c_comb3[0]), .c_out(c_comb3[1]) ); // c[1] = G(0,0) | (P(0,0) & c[0])
  gray_cell gc_3_3 ( .G(g_r1[2]), .P(p_r1[2]), .c_in(c_comb3[2]), .c_out(c_comb3[3]) ); // c[3] = G(2,2) | (P(2,2) & c[2])
  gray_cell gc_3_5 ( .G(g_r1[4]), .P(p_r1[4]), .c_in(c_comb3[4]), .c_out(c_comb3[5]) ); // c[5] = G(4,4) | (P(4,4) & c[4])
  gray_cell gc_3_6 ( .G(GP_l1_r1[5]), .P(PP_l1_r1[5]), .c_in(c_comb3[4]), .c_out(c_comb3[6]) ); // c[6] = G(4..5) | (P(4..5) & c[4])
  gray_cell gc_3_7 ( .G(g_r1[6]), .P(p_r1[6]), .c_in(c_comb3[6]), .c_out(c_comb3[7]) ); // c[7] = G(6,6) | (P(6,6) & c[6])

  // Sum Calculation using registered P and calculated carries
  // sum[i] = p_r1[i] ^ c_comb3[i]
  sum_cell sc_3_0 ( .P(p_r1[0]), .c_in(c_comb3[0]), .sum_bit(sum_comb3[0]) );
  sum_cell sc_3_1 ( .P(p_r1[1]), .c_in(c_comb3[1]), .sum_bit(sum_comb3[1]) );
  sum_cell sc_3_2 ( .P(p_r1[2]), .c_in(c_comb3[2]), .sum_bit(sum_comb3[2]) );
  sum_cell sc_3_3 ( .P(p_r1[3]), .c_in(c_comb3[3]), .sum_bit(sum_comb3[3]) );
  sum_cell sc_3_4 ( .P(p_r1[4]), .c_in(c_comb3[4]), .sum_bit(sum_comb3[4]) );
  sum_cell sc_3_5 ( .P(p_r1[5]), .c_in(c_comb3[5]), .sum_bit(sum_comb3[5]) );
  sum_cell sc_3_6 ( .P(p_r1[6]), .c_in(c_comb3[6]), .sum_bit(sum_comb3[6]) );
  sum_cell sc_3_7 ( .P(p_r1[7]), .c_in(c_comb3[7]), .sum_bit(sum_comb3[7]) );

  // Stage 3 Registers (Output Registers)
  reg [7:0] sum_r3;
  reg cout_r3;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      sum_r3 <= 8'b0;
      cout_r3 <= 1'b0;
    end else begin
      sum_r3 <= sum_comb3;
      cout_r3 <= c_comb3[8]; // cout is the carry out of the MSB
    end
  end

  // Final Outputs
  assign sum = sum_r3;
  assign cout = cout_r3;

endmodule

// black_cell module definition
module black_cell (
    input wire G1,
    input wire P1,
    input wire G0,
    input wire P0,
    output wire G_out,
    output wire P_out
);
  assign G_out = G1 | (P1 & G0);
  assign P_out = P1 & P0;
endmodule

// gray_cell module definition
module gray_cell (
    input wire G,
    input wire P,
    input wire c_in,
    output wire c_out
);
  assign c_out = G | (P & c_in);
endmodule

// sum_cell module definition
module sum_cell (
    input wire P,
    input wire c_in,
    output wire sum_bit
);
  assign sum_bit = P ^ c_in;
endmodule