//SystemVerilog
module RD6 #(parameter WIDTH=8, DEPTH=4)(
  input clk, input arstn,
  input [WIDTH-1:0] shift_in,
  output [WIDTH-1:0] shift_out
);
  // Intermediate signals for the parallel prefix adder implementation
  reg [WIDTH-1:0] data_reg;
  wire [WIDTH-1:0] adder_result;
  
  // Shift register stages implementation
  reg [WIDTH-1:0] shreg_stage1 [0:DEPTH-1];
  reg [WIDTH-1:0] shreg_stage2 [0:DEPTH-1];
  
  integer j;
  
  // Instantiate the parallel prefix adder
  ParallelPrefixAdder #(.WIDTH(WIDTH)) ppa_inst (
    .a(data_reg),
    .b(shift_in),
    .sum(adder_result)
  );
  
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      data_reg <= {WIDTH{1'b0}};
      for (j=0; j<DEPTH; j=j+1) begin
        shreg_stage1[j] <= {WIDTH{1'b0}};
        shreg_stage2[j] <= {WIDTH{1'b0}};
      end
    end else begin
      // Store input for adder operation
      data_reg <= shift_in;
      
      // First stage pipeline with adder result
      shreg_stage1[0] <= adder_result;
      for (j=1; j<DEPTH; j=j+1) begin
        shreg_stage1[j] <= shreg_stage2[j-1];
      end
      
      // Second stage pipeline
      for (j=0; j<DEPTH; j=j+1) begin
        shreg_stage2[j] <= shreg_stage1[j];
      end
    end
  end
  
  assign shift_out = shreg_stage2[DEPTH-1];
endmodule

// Parallel Prefix Adder module
module ParallelPrefixAdder #(parameter WIDTH=8)(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  output [WIDTH-1:0] sum
);
  // Propagate and generate signals
  wire [WIDTH-1:0] p, g;  // Initial propagate and generate
  wire [WIDTH-1:0] p_stage1, g_stage1; // Stage 1 signals
  wire [WIDTH-1:0] p_stage2, g_stage2; // Stage 2 signals
  wire [WIDTH-1:0] p_stage3, g_stage3; // Stage 3 signals
  wire [WIDTH-1:0] carry;
  
  // Step 1: Generate initial propagate and generate signals
  assign p = a ^ b;  // Propagate: p_i = a_i XOR b_i
  assign g = a & b;  // Generate: g_i = a_i AND b_i
  
  // Step 2: Black cell operations across multiple stages (parallel prefix computation)
  // Stage 1: Combine adjacent pairs
  generate
    // First bit is kept as is
    assign p_stage1[0] = p[0];
    assign g_stage1[0] = g[0];
    
    // Combine pairs for remaining bits
    for (genvar i = 1; i < WIDTH; i = i + 1) begin
      // Black cell operation: combine P and G signals
      if (i == 1) begin
        assign p_stage1[i] = p[i] & p[i-1];
        assign g_stage1[i] = g[i] | (p[i] & g[i-1]);
      end else begin
        assign p_stage1[i] = p[i];
        assign g_stage1[i] = g[i];
      end
    end
    
    // Stage 2: Combine with 2-bit distance
    for (genvar i = 0; i < WIDTH; i = i + 1) begin
      if (i < 2) begin
        assign p_stage2[i] = p_stage1[i];
        assign g_stage2[i] = g_stage1[i];
      end else begin
        assign p_stage2[i] = p_stage1[i] & p_stage1[i-2];
        assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
      end
    end
    
    // Stage 3: Combine with 4-bit distance
    for (genvar i = 0; i < WIDTH; i = i + 1) begin
      if (i < 4) begin
        assign p_stage3[i] = p_stage2[i];
        assign g_stage3[i] = g_stage2[i];
      end else begin
        assign p_stage3[i] = p_stage2[i] & p_stage2[i-4];
        assign g_stage3[i] = g_stage2[i] | (p_stage2[i] & g_stage2[i-4]);
      end
    end
  endgenerate
  
  // Step 3: Compute the carry signals
  assign carry[0] = 1'b0; // No carry input
  
  generate
    for (genvar i = 1; i < WIDTH; i = i + 1) begin
      if (i <= 4)
        assign carry[i] = g_stage3[i-1];
      else
        assign carry[i] = g_stage3[i-1];
    end
  endgenerate
  
  // Step 4: Compute the sum
  assign sum = p ^ carry;
endmodule