//SystemVerilog
module moore_3state_glitch_filter(
  input  clk,
  input  rst,
  input  in,
  output reg out
);
  reg [1:0] state, next_state;
  localparam STABLE0 = 2'b00,
             TRANS   = 2'b01,
             STABLE1 = 2'b10;

  // Kogge-Stone multiplier implementation
  wire [3:0] a, b; // Inputs for multiplication
  wire [3:0] p;    // Product output
  wire [3:0] g, p_temp; // Generate and propagate signals
  wire [3:0] sum; // Intermediate sums

  assign a = {2'b00, in}; // Extend input to 4 bits
  assign b = {2'b00, in}; // Extend input to 4 bits

  // Generate and propagate
  assign g = a & b; // Generate
  assign p_temp = a ^ b; // Propagate

  // Kogge-Stone tree structure for addition
  assign sum[0] = g[0];
  assign sum[1] = g[1] ^ (g[0] & p_temp[1]);
  assign sum[2] = g[2] ^ (g[1] & p_temp[2]) ^ (g[0] & p_temp[1] & p_temp[2]);
  assign sum[3] = g[3] ^ (g[2] & p_temp[3]) ^ (g[1] & p_temp[2] & p_temp[3]) ^ (g[0] & p_temp[1] & p_temp[2] & p_temp[3]);

  always @(posedge clk or posedge rst) begin
    if (rst) state <= STABLE0;
    else     state <= next_state;
  end

  always @* begin
    if (state == STABLE0) begin
      if (in) next_state = TRANS;
      else     next_state = STABLE0;
    end else if (state == TRANS) begin
      if (in) next_state = STABLE1;
      else     next_state = STABLE0;
    end else if (state == STABLE1) begin
      if (in) next_state = STABLE1;
      else     next_state = TRANS;
    end
  end

  always @* begin
    if (state == STABLE1) 
      out = 1;
    else 
      out = 0;
  end
endmodule