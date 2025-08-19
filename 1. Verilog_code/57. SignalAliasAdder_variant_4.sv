//SystemVerilog
module alias_add(
  input [5:0] primary,
  input [5:0] secondary,
  output [6:0] aggregate
);

  // Manchester carry chain adder submodule
  manchester_adder_6bit u_adder(
    .a(primary),
    .b(secondary),
    .sum(aggregate)
  );

endmodule

module manchester_adder_6bit(
  input [5:0] a,
  input [5:0] b,
  output [6:0] sum
);

  wire [5:0] g;  // Generate signals
  wire [5:0] p;  // Propagate signals
  wire [5:0] c;  // Carry signals
  
  // Generate and propagate signals
  genvar i;
  generate
    for(i=0; i<6; i=i+1) begin : gen_manchester
      assign g[i] = a[i] & b[i];
      assign p[i] = a[i] ^ b[i];
    end
  endgenerate

  // Manchester carry chain
  assign c[0] = g[0] | (p[0] & 1'b0);
  assign c[1] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & 1'b0);
  assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & 1'b0);
  assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & 1'b0);
  assign c[4] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & 1'b0);
  assign c[5] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & 1'b0);

  // Sum calculation
  assign sum[0] = p[0];
  assign sum[1] = p[1] ^ c[0];
  assign sum[2] = p[2] ^ c[1];
  assign sum[3] = p[3] ^ c[2];
  assign sum[4] = p[4] ^ c[3];
  assign sum[5] = p[5] ^ c[4];
  assign sum[6] = c[5];

endmodule