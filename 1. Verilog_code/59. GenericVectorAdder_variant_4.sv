//SystemVerilog
module vec_add #(parameter W=8)(
  input [W-1:0] vec1, vec2,
  output [W:0] vec_out
);

  // Han-Carlson adder implementation
  wire [W-1:0] g, p;
  wire [W-1:0] g_stage1, p_stage1;
  wire [W-1:0] g_stage2, p_stage2;
  wire [W-1:0] g_stage3, p_stage3;
  wire [W:0] c;

  // Stage 1: Generate and propagate signals
  genvar i;
  generate
    for(i=0; i<W; i=i+1) begin: gen_prop
      assign g[i] = vec1[i] & vec2[i];
      assign p[i] = vec1[i] ^ vec2[i];
    end
  endgenerate

  // Stage 2: First level of prefix computation
  assign g_stage1[0] = g[0];
  assign p_stage1[0] = p[0];
  generate
    for(i=1; i<W; i=i+1) begin: stage1
      assign g_stage1[i] = g[i] | (p[i] & g[i-1]);
      assign p_stage1[i] = p[i] & p[i-1];
    end
  endgenerate

  // Stage 3: Second level of prefix computation
  assign g_stage2[0] = g_stage1[0];
  assign p_stage2[0] = p_stage1[0];
  assign g_stage2[1] = g_stage1[1];
  assign p_stage2[1] = p_stage1[1];
  generate
    for(i=2; i<W; i=i+1) begin: stage2
      assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
      assign p_stage2[i] = p_stage1[i] & p_stage1[i-2];
    end
  endgenerate

  // Stage 4: Final level of prefix computation
  assign g_stage3[0] = g_stage2[0];
  assign p_stage3[0] = p_stage2[0];
  assign g_stage3[1] = g_stage2[1];
  assign p_stage3[1] = p_stage2[1];
  assign g_stage3[2] = g_stage2[2];
  assign p_stage3[2] = p_stage2[2];
  assign g_stage3[3] = g_stage2[3];
  assign p_stage3[3] = p_stage2[3];
  generate
    for(i=4; i<W; i=i+1) begin: stage3
      assign g_stage3[i] = g_stage2[i] | (p_stage2[i] & g_stage2[i-4]);
      assign p_stage3[i] = p_stage2[i] & p_stage2[i-4];
    end
  endgenerate

  // Generate carry signals
  assign c[0] = 1'b0;
  generate
    for(i=0; i<W; i=i+1) begin: carry_gen
      assign c[i+1] = g_stage3[i];
    end
  endgenerate

  // Final sum computation
  assign vec_out[W-1:0] = p ^ c[W-1:0];
  assign vec_out[W] = c[W];

endmodule