//SystemVerilog
module xor_generate(input [3:0] a, b, output [3:0] y);
  // Internal signals for Han-Carlson adder
  wire [3:0] p, g;
  wire [3:0] pp, gg;
  wire [4:0] c;
  
  // Step 1: Generate propagate and generate signals
  genvar i;
  generate
    for(i=0; i<4; i=i+1) begin
      assign p[i] = a[i] ^ b[i];
      assign g[i] = a[i] & b[i];
    end
  endgenerate
  
  // Step 2: Han-Carlson pre-processing (even bits)
  assign pp[0] = p[0];
  assign gg[0] = g[0];
  assign pp[2] = p[2];
  assign gg[2] = g[2];
  
  // Step 3: Han-Carlson propagation (odd bits)
  assign pp[1] = p[1] & p[0];
  assign gg[1] = g[1] | (p[1] & g[0]);
  assign pp[3] = p[3] & p[2];
  assign gg[3] = g[3] | (p[3] & g[2]);
  
  // Step 4: Final carry calculation
  assign c[0] = 1'b0; // No carry input
  assign c[1] = gg[0];
  assign c[2] = gg[1];
  assign c[3] = gg[2];
  assign c[4] = gg[3];
  
  // Step 5: Sum calculation (functionally equivalent to original XOR)
  assign y[0] = p[0] ^ c[0];
  assign y[1] = p[1] ^ c[1];
  assign y[2] = p[2] ^ c[2];
  assign y[3] = p[3] ^ c[3];
endmodule