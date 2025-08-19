//SystemVerilog
module cat_add #(parameter N=8)(
  input [N-1:0] in1, in2,
  output [N:0] out
);

  // Ensure N is 8 for this specific Brent-Kung implementation
  // synthesis translate_off
  initial begin
    if (N != 8) $fatal("Brent-Kung adder implementation is fixed to N=8");
  end
  // synthesis translate_on

  // Internal signals declared as reg for use in always_comb blocks
  reg [N-1:0] gp0_p_reg, gp0_g_reg; // Level 0 Generate/Propagate (p_i, g_i)
  reg [N-1:0] gp1_p_reg, gp1_g_reg; // Level 1 (dist 2) terms (P_{i:i-1}, G_{i:i-1})
  reg [N-1:0] gp2_p_reg, gp2_g_reg; // Level 2 (dist 4) terms (P_{i:i-3}, G_{i:i-3})
  reg [N-1:0] gp3_p_reg, gp3_g_reg; // Level 3 (dist 8) terms (P_{i:i-7}, G_{i:i-7})

  reg [N:0] c_reg; // Carries c_0 to c_N
  reg [N-1:0] sum_reg; // Sum bits

  genvar i;

  // Level 0: Initial P and G (dist 1) using always_comb and conditional logic
  generate
    for (i = 0; i < N; i = i + 1) begin : gen_gp0
      always_comb begin
        // p_i = in1[i] ^ in2[i];
        if (in1[i] != in2[i]) begin
          gp0_p_reg[i] = 1'b1;
        end else begin
          gp0_p_reg[i] = 1'b0;
        end

        // g_i = in1[i] & in2[i];
        if (in1[i] == 1'b1 && in2[i] == 1'b1) begin
          gp0_g_reg[i] = 1'b1;
        end else begin
          gp0_g_reg[i] = 1'b0;
        end
      end
    end
  endgenerate

  // Level 1: Compute GP terms with distance 2 (Black cells)
  // GP(i, i-1) from gp0(i) and gp0(i-1)
  always_comb begin // gp1_p[1] = gp0_p[1] & gp0_p[0];
    if (gp0_p_reg[1] == 1'b1 && gp0_p_reg[0] == 1'b1) gp1_p_reg[1] = 1'b1; else gp1_p_reg[1] = 1'b0;
  end
  always_comb begin // gp1_g[1] = gp0_g[1] | (gp0_p[1] & gp0_g[0]);
    if (gp0_g_reg[1] == 1'b1) gp1_g_reg[1] = 1'b1;
    else if (gp0_p_reg[1] == 1'b1 && gp0_g_reg[0] == 1'b1) gp1_g_reg[1] = 1'b1;
    else gp1_g_reg[1] = 1'b0;
  end

  always_comb begin // gp1_p[3] = gp0_p[3] & gp0_p[2];
    if (gp0_p_reg[3] == 1'b1 && gp0_p_reg[2] == 1'b1) gp1_p_reg[3] = 1'b1; else gp1_p_reg[3] = 1'b0;
  end
  always_comb begin // gp1_g[3] = gp0_g[3] | (gp0_p[3] & gp0_g[2]);
    if (gp0_g_reg[3] == 1'b1) gp1_g_reg[3] = 1'b1;
    else if (gp0_p_reg[3] == 1'b1 && gp0_g_reg[2] == 1'b1) gp1_g_reg[3] = 1'b1;
    else gp1_g_reg[3] = 1'b0;
  end

  always_comb begin // gp1_p[5] = gp0_p[5] & gp0_p[4];
    if (gp0_p_reg[5] == 1'b1 && gp0_p_reg[4] == 1'b1) gp1_p_reg[5] = 1'b1; else gp1_p_reg[5] = 1'b0;
  end
  always_comb begin // gp1_g[5] = gp0_g[5] | (gp0_p[5] & gp0_g[4]);
    if (gp0_g_reg[5] == 1'b1) gp1_g_reg[5] = 1'b1;
    else if (gp0_p_reg[5] == 1'b1 && gp0_g_reg[4] == 1'b1) gp1_g_reg[5] = 1'b1;
    else gp1_g_reg[5] = 1'b0;
  end

  always_comb begin // gp1_p[7] = gp0_p[7] & gp0_p[6];
    if (gp0_p_reg[7] == 1'b1 && gp0_p_reg[6] == 1'b1) gp1_p_reg[7] = 1'b1; else gp1_p_reg[7] = 1'b0;
  end
  always_comb begin // gp1_g[7] = gp0_g[7] | (gp0_p[7] & gp0_g[6]);
    if (gp0_g_reg[7] == 1'b1) gp1_g_reg[7] = 1'b1;
    else if (gp0_p_reg[7] == 1'b1 && gp0_g_reg[6] == 1'b1) gp1_g_reg[7] = 1'b1;
    else gp1_g_reg[7] = 1'b0;
  end


  // Level 2: Compute GP terms with distance 4 (Black cells)
  // GP(i, i-3) from gp1(i) and gp1(i-2)
  always_comb begin // gp2_p[3] = gp1_p[3] & gp1_p[1];
    if (gp1_p_reg[3] == 1'b1 && gp1_p_reg[1] == 1'b1) gp2_p_reg[3] = 1'b1; else gp2_p_reg[3] = 1'b0;
  end
  always_comb begin // gp2_g[3] = gp1_g[3] | (gp1_p[3] & gp1_g[1]);
    if (gp1_g_reg[3] == 1'b1) gp2_g_reg[3] = 1'b1;
    else if (gp1_p_reg[3] == 1'b1 && gp1_g_reg[1] == 1'b1) gp2_g_reg[3] = 1'b1;
    else gp2_g_reg[3] = 1'b0;
  end

  always_comb begin // gp2_p[7] = gp1_p[7] & gp1_p[5];
    if (gp1_p_reg[7] == 1'b1 && gp1_p_reg[5] == 1'b1) gp2_p_reg[7] = 1'b1; else gp2_p_reg[7] = 1'b0;
  end
  always_comb begin // gp2_g[7] = gp1_g[7] | (gp1_p[7] & gp1_g[5]);
    if (gp1_g_reg[7] == 1'b1) gp2_g_reg[7] = 1'b1;
    else if (gp1_p_reg[7] == 1'b1 && gp1_g_reg[5] == 1'b1) gp2_g_reg[7] = 1'b1;
    else gp2_g_reg[7] = 1'b0;
  end

  // Level 3: Compute GP terms with distance 8 (Black cell)
  // GP(i, i-7) from gp2(i) and gp2(i-4)
  always_comb begin // gp3_p[7] = gp2_p[7] & gp2_p[3];
    if (gp2_p_reg[7] == 1'b1 && gp2_p_reg[3] == 1'b1) gp3_p_reg[7] = 1'b1; else gp3_p_reg[7] = 1'b0;
  end
  always_comb begin // gp3_g[7] = gp2_g[7] | (gp2_p[7] & gp2_p[3]);
    if (gp2_g_reg[7] == 1'b1) gp3_g_reg[7] = 1'b1;
    else if (gp2_p_reg[7] == 1'b1 && gp2_g_reg[3] == 1'b1) gp3_g_reg[7] = 1'b1;
    else gp3_g_reg[7] = 1'b0;
  end

  // Carry computation (Backward pass) using always_comb and conditional logic
  // ci is carry INTO bit i. c0 is input carry (0).
  always_comb begin c_reg[0] = 1'b0; end // c[0] = 1'b0;
  always_comb begin c_reg[1] = gp0_g_reg[0]; end // c[1] = gp0_g[0]; // G(0:0)
  always_comb begin c_reg[2] = gp1_g_reg[1]; end // c[2] = gp1_g[1]; // G(1:0)

  always_comb begin // c[3] = gp0_g[2] | (gp0_p[2] & c[2]); // G(2:0) = GP(2:2) o G(1:0)
    if (gp0_g_reg[2] == 1'b1) c_reg[3] = 1'b1;
    else if (gp0_p_reg[2] == 1'b1 && c_reg[2] == 1'b1) c_reg[3] = 1'b1;
    else c_reg[3] = 1'b0;
  end

  always_comb begin c_reg[4] = gp2_g_reg[3]; end // c[4] = gp2_g[3]; // G(3:0)

  always_comb begin // c[5] = gp0_g[4] | (gp0_p[4] & c[4]); // G(4:0) = GP(4:4) o G(3:0)
    if (gp0_g_reg[4] == 1'b1) c_reg[5] = 1'b1;
    else if (gp0_p_reg[4] == 1'b1 && c_reg[4] == 1'b1) c_reg[5] = 1'b1;
    else c_reg[5] = 1'b0;
  end

  always_comb begin // c[6] = gp1_g[5] | (gp1_p[5] & c[4]); // G(5:0) = GP(5:4) o G(3:0)
    if (gp1_g_reg[5] == 1'b1) c_reg[6] = 1'b1;
    else if (gp1_p_reg[5] == 1'b1 && c_reg[4] == 1'b1) c_reg[6] = 1'b1;
    else c_reg[6] = 1'b0;
  end

  always_comb begin // c[7] = gp0_g[6] | (gp0_p[6] & c[6]); // G(6:0) = GP(6:6) o G(5:0)
    if (gp0_g_reg[6] == 1'b1) c_reg[7] = 1'b1;
    else if (gp0_p_reg[6] == 1'b1 && c_reg[6] == 1'b1) c_reg[7] = 1'b1;
    else c_reg[7] = 1'b0;
  end

  always_comb begin c_reg[8] = gp3_g_reg[7]; end // c[8] = gp3_g[7]; // G(7:0) - Carry out

  // Final Sum using always_comb and conditional logic
  generate
    for (i = 0; i < N; i = i + 1) begin : gen_sum
      always_comb begin
        // s_i = p_i ^ c_i
        if (gp0_p_reg[i] != c_reg[i]) begin
          sum_reg[i] = 1'b1;
        end else begin
          sum_reg[i] = 1'b0;
        end
      end
    end
  endgenerate

  // Assign internal reg signals to output wire
  assign out = {c_reg[N], sum_reg};

endmodule