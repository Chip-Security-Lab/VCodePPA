//SystemVerilog
module reset_freq_counter(
  input clk,
  input rst_n,
  input ext_rst_n,
  input wdt_rst_n,
  output reg [7:0] ext_rst_count,
  output reg [7:0] wdt_rst_count,
  output reg any_reset
);
  reg ext_rst_prev, wdt_rst_prev;
  wire ext_rst_falling, wdt_rst_falling;

  // 8-bit Carry Lookahead Adder for ext_rst_count
  wire [7:0] ext_rst_count_next;
  wire ext_rst_carry_out;
  carry_lookahead_adder_8bit ext_rst_cla_adder (
    .a(ext_rst_count),
    .b(8'd1),
    .cin(1'b0),
    .sum(ext_rst_count_next),
    .cout(ext_rst_carry_out)
  );

  // 8-bit Carry Lookahead Adder for wdt_rst_count
  wire [7:0] wdt_rst_count_next;
  wire wdt_rst_carry_out;
  carry_lookahead_adder_8bit wdt_rst_cla_adder (
    .a(wdt_rst_count),
    .b(8'd1),
    .cin(1'b0),
    .sum(wdt_rst_count_next),
    .cout(wdt_rst_carry_out)
  );

  assign ext_rst_falling = ext_rst_prev & ~ext_rst_n;
  assign wdt_rst_falling = wdt_rst_prev & ~wdt_rst_n;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ext_rst_count <= 8'd0;
      wdt_rst_count <= 8'd0;
      ext_rst_prev  <= 1'b1;
      wdt_rst_prev  <= 1'b1;
      any_reset     <= 1'b0;
    end else begin
      ext_rst_prev  <= ext_rst_n;
      wdt_rst_prev  <= wdt_rst_n;
      if (ext_rst_falling)
        ext_rst_count <= ext_rst_count_next;
      if (wdt_rst_falling)
        wdt_rst_count <= wdt_rst_count_next;
      any_reset <= (~ext_rst_n) | (~wdt_rst_n);
    end
  end
endmodule

module carry_lookahead_adder_8bit(
  input  [7:0] a,
  input  [7:0] b,
  input        cin,
  output [7:0] sum,
  output       cout
);
  wire [7:0] p;  // propagate
  wire [7:0] g;  // generate
  wire [8:0] c;  // carry

  assign p = a ^ b;
  assign g = a & b;

  assign c[0] = cin;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
  assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
  assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
  assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
  assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

  assign sum = p ^ c[7:0];
  assign cout = c[8];
endmodule