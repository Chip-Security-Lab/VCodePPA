//SystemVerilog
// SystemVerilog

// Top-level module for an 8-bit Kogge-Stone adder
// Refactored into hierarchical submodules
module split_add #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] m,
    input  wire [DATA_WIDTH-1:0] n,
    output wire [DATA_WIDTH  :0] total
);

  // Internal wires connecting submodules
  wire [DATA_WIDTH-1:0] p0; // Initial Propagate
  wire [DATA_WIDTH-1:0] g0; // Initial Generate

  wire [DATA_WIDTH-1:0] p1; // Stage 1 Propagate
  wire [DATA_WIDTH-1:0] g1; // Stage 1 Generate

  wire [DATA_WIDTH-1:0] p2; // Stage 2 Propagate
  wire [DATA_WIDTH-1:0] g2; // Stage 2 Generate

  wire [DATA_WIDTH-1:0] p3; // Stage 3 Propagate (Final prefix P)
  wire [DATA_WIDTH-1:0] g3; // Stage 3 Generate (Final prefix G)

  wire [DATA_WIDTH  :0] carries;  // carries[i] is the carry into bit i, carries[DATA_WIDTH] is the carry-out
  wire [DATA_WIDTH-1:0] sum_bits; // Individual sum bits

  // Instantiate submodules

  // 1. Initial P and G calculation
  initial_pg_gen #(
      .DATA_WIDTH(DATA_WIDTH)
  ) u_initial_pg (
      .m(m),
      .n(n),
      .p0(p0),
      .g0(g0)
  );

  // 2. Kogge-Stone Prefix Tree Stages
  // Stage 1 (distance 1)
  kogge_stone_stage #(
      .DATA_WIDTH(DATA_WIDTH),
      .DISTANCE(1)
  ) u_ks_stage1 (
      .p_in(p0),
      .g_in(g0),
      .p_out(p1),
      .g_out(g1)
  );

  // Stage 2 (distance 2)
  kogge_stone_stage #(
      .DATA_WIDTH(DATA_WIDTH),
      .DISTANCE(2)
  ) u_ks_stage2 (
      .p_in(p1),
      .g_in(g1),
      .p_out(p2),
      .g_out(g2)
  );

  // Stage 3 (distance 4)
  kogge_stone_stage #(
      .DATA_WIDTH(DATA_WIDTH),
      .DISTANCE(4)
  ) u_ks_stage3 (
      .p_in(p2),
      .g_in(g2),
      .p_out(p3),
      .g_out(g3)
  );

  // 3. Carry calculation from final prefix G
  carry_calculator #(
      .DATA_WIDTH(DATA_WIDTH)
  ) u_carry_calc (
      .g_final(g3),
      .carry_in(1'b0), // Assume no carry-in for this specific implementation
      .carries(carries)
  );

  // 4. Sum bit calculation
  sum_calculator #(
      .DATA_WIDTH(DATA_WIDTH)
  ) u_sum_calc (
      .p0(p0),
      .carries_into_bits(carries[DATA_WIDTH-1:0]), // Carries into bits 0 to DATA_WIDTH-1
      .sum_bits(sum_bits)
  );

  // Final Output (9-bit sum for 8-bit inputs)
  assign total = {carries[DATA_WIDTH], sum_bits}; // carries[DATA_WIDTH] is the carry-out

endmodule


// Submodule: Calculates initial Generate and Propagate signals
module initial_pg_gen #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] m,
    input  wire [DATA_WIDTH-1:0] n,
    output wire [DATA_WIDTH-1:0] p0, // Propagate: m[i] ^ n[i]
    output wire [DATA_WIDTH-1:0] g0  // Generate: m[i] & n[i]
);

  assign p0 = m ^ n;
  assign g0 = m & n;

endmodule


// Submodule: Performs one stage of the Kogge-Stone prefix calculation
// Computes P_out and G_out based on P_in, G_in and the stage DISTANCE
module kogge_stone_stage #(
    parameter DATA_WIDTH = 8,
    parameter DISTANCE   = 1 // Distance for this stage (1, 2, 4, etc.)
) (
    input  wire [DATA_WIDTH-1:0] p_in,
    input  wire [DATA_WIDTH-1:0] g_in,
    output wire [DATA_WIDTH-1:0] p_out,
    output wire [DATA_WIDTH-1:0] g_out
);

  generate
    for (genvar i = 0; i < DATA_WIDTH; i = i + 1) begin : stage_gen
      if (i < DISTANCE) begin
        // Buffer the first 'DISTANCE' bits
        assign g_out[i] = g_in[i];
        assign p_out[i] = p_in[i];
      end else begin
        // Kogge-Stone prefix logic
        assign g_out[i] = g_in[i] | (p_in[i] & g_in[i-DISTANCE]);
        assign p_out[i] = p_in[i] & p_in[i-DISTANCE];
      end
    end
  endgenerate

endmodule


// Submodule: Calculates carries based on the final prefix Generate signals
// carries[i] is the carry into bit i
module carry_calculator #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] g_final,       // Final prefix Generate signals (g3 in top)
    input  wire                  carry_in,      // Input carry into bit 0
    output wire [DATA_WIDTH  :0] carries        // carries[i] is carry into bit i, carries[DATA_WIDTH] is carry-out
);

  assign carries[0] = carry_in;

  generate
    for (genvar i = 0; i < DATA_WIDTH; i = i + 1) begin : carry_gen
      // carries[i+1] is the carry into bit i+1, which is the final generate signal g_final[i]
      assign carries[i+1] = g_final[i];
    end
  endgenerate

endmodule


// Submodule: Calculates individual sum bits
module sum_calculator #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] p0,               // Initial Propagate signals
    input  wire [DATA_WIDTH-1:0] carries_into_bits,// Carries into each bit position (carries[0] to carries[DATA_WIDTH-1] from carry_calculator)
    output wire [DATA_WIDTH-1:0] sum_bits          // Individual sum bits
);

  generate
    for (genvar i = 0; i < DATA_WIDTH; i = i + 1) begin : sum_gen
      // Sum[i] = P0[i] XOR Carry_in[i]
      assign sum_bits[i] = p0[i] ^ carries_into_bits[i];
    end
  endgenerate

endmodule