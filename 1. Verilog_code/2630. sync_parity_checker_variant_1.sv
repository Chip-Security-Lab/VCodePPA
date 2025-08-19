//SystemVerilog
module sync_parity_checker(
  input clk, rst,
  input [7:0] data,
  input parity_in,
  input req,
  output reg ack,
  output reg error,
  output reg [3:0] error_count
);
  wire [3:0] next_error_count;
  reg req_reg;
  reg data_valid;

  han_carlson_adder #(
    .WIDTH(4)
  ) error_counter (
    .a(error_count),
    .b(4'b0001),
    .cin(1'b0),
    .sum(next_error_count),
    .cout()
  );

  always @(posedge clk) begin
    if (rst) begin
      error <= 1'b0;
      error_count <= 4'd0;
      ack <= 1'b0;
      req_reg <= 1'b0;
      data_valid <= 1'b0;
    end else begin
      req_reg <= req;
      if (req && !req_reg) begin
        data_valid <= 1'b1;
        ack <= 1'b1;
      end else if (ack) begin
        ack <= 1'b0;
        data_valid <= 1'b0;
      end

      if (data_valid) begin
        error <= (^data) ^ parity_in;
        if ((^data) ^ parity_in)
          error_count <= next_error_count;
      end
    end
  end
endmodule

module han_carlson_adder #(
  parameter WIDTH = 4
)(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  input cin,
  output [WIDTH-1:0] sum,
  output cout
);
  wire [WIDTH-1:0] p, g;
  wire [WIDTH-1:0] pp[1:0];
  wire [WIDTH-1:0] gg[1:0];
  wire [WIDTH:0] c;
  
  assign p = a ^ b;
  assign g = a & b;
  assign c[0] = cin;
  
  genvar i, j;
  generate
    for (i = 0; i < WIDTH; i = i + 2) begin: hc_level0_even
      if (i == 0) begin
        assign gg[0][i] = g[i] | (p[i] & c[0]);
        assign pp[0][i] = p[i];
      end else begin
        assign gg[0][i] = g[i] | (p[i] & g[i-1]);
        assign pp[0][i] = p[i] & p[i-1];
      end
    end
    
    for (i = 2; i < WIDTH; i = i + 2) begin: hc_level1_even
      assign gg[1][i] = gg[0][i] | (pp[0][i] & gg[0][i-2]);
      assign pp[1][i] = pp[0][i] & pp[0][i-2];
    end
    
    for (i = 1; i < WIDTH; i = i + 2) begin: odd_propagate
      if (i == 1) begin
        assign c[i] = g[i-1] | (p[i-1] & c[0]);
      end else begin
        assign c[i] = gg[1][i-1];
      end
    end
    
    for (i = 2; i < WIDTH; i = i + 2) begin: even_carry
      assign c[i] = gg[1][i];
    end
    
    if (WIDTH % 2 == 0) begin
      assign c[WIDTH] = gg[1][WIDTH-2];
    end else begin
      assign c[WIDTH] = g[WIDTH-1] | (p[WIDTH-1] & c[WIDTH-1]);
    end
  endgenerate
  
  assign sum = p ^ c[WIDTH-1:0];
  assign cout = c[WIDTH];
endmodule