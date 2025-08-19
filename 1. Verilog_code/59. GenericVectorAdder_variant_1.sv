//SystemVerilog
// SystemVerilog
// Top-level module
module vec_add #(parameter W=8)(
  input [W-1:0] vec1, vec2,
  output [W:0] vec_out
);

  // Generate and Propagate signals
  wire [W-1:0] g, p;
  wire [W-1:0] g_out, p_out;
  wire [W:0] sum;
  
  // Instantiate generate_propagate module
  generate_propagate #(.W(W)) gp_unit (
    .vec1(vec1),
    .vec2(vec2),
    .g(g),
    .p(p)
  );
  
  // Instantiate parallel_prefix module
  parallel_prefix #(.W(W)) pp_unit (
    .g(g),
    .p(p),
    .g_out(g_out),
    .p_out(p_out)
  );
  
  // Instantiate sum_computation module
  sum_computation #(.W(W)) sum_unit (
    .p(p),
    .g_out(g_out),
    .sum(sum)
  );
  
  assign vec_out = sum;
  
endmodule

// Generate and Propagate computation module
module generate_propagate #(parameter W=8)(
  input [W-1:0] vec1, vec2,
  output [W-1:0] g, p
);
  assign g = vec1 & vec2;
  assign p = vec1 ^ vec2;
endmodule

// Parallel prefix computation module
module parallel_prefix #(parameter W=8)(
  input [W-1:0] g, p,
  output [W-1:0] g_out, p_out
);
  assign g_out[0] = g[0];
  assign p_out[0] = p[0];
  
  genvar i;
  generate
    for(i=1; i<W; i=i+1) begin: prefix
      assign g_out[i] = g[i] | (p[i] & g_out[i-1]);
      assign p_out[i] = p[i] & p_out[i-1];
    end
  endgenerate
endmodule

// Sum computation module
module sum_computation #(parameter W=8)(
  input [W-1:0] p, g_out,
  output [W:0] sum
);
  assign sum[0] = p[0];
  
  genvar i;
  generate
    for(i=1; i<W; i=i+1) begin: sum_gen
      assign sum[i] = p[i] ^ g_out[i-1];
    end
  endgenerate
  assign sum[W] = g_out[W-1];
endmodule