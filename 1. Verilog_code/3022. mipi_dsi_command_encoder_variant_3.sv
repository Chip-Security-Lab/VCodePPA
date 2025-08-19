//SystemVerilog
module mipi_dsi_command_encoder (
  input wire clk, reset_n,
  input wire [7:0] cmd_type,
  input wire [15:0] parameter_data,
  input wire [3:0] parameter_count,
  input wire encode_start,
  output reg [31:0] packet_data,
  output reg packet_ready,
  output reg busy
);

  reg [3:0] state;
  reg [3:0] param_idx;
  reg [7:0] ecc;
  
  // Kogge-Stone adder signals
  wire [31:0] sum;
  wire [31:0] carry;
  wire [31:0] prop;
  wire [31:0] gen;
  
  // Generate and propagate signals
  assign gen = {24'h0, cmd_type} & {24'h0, 8'hFF};
  assign prop = {24'h0, cmd_type} ^ {24'h0, 8'hFF};
  
  // Kogge-Stone adder implementation
  kogge_stone_adder #(.WIDTH(32)) u_adder (
    .a({24'h0, cmd_type}),
    .b({24'h0, 8'hFF}),
    .cin(1'b0),
    .sum(sum),
    .cout()
  );
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      packet_data <= 32'h0;
      packet_ready <= 1'b0;
      busy <= 1'b0;
      param_idx <= 4'd0;
    end else if (encode_start && !busy) begin
      busy <= 1'b1;
      packet_data[7:0] <= cmd_type;
      packet_data[15:8] <= 8'h00;
      packet_data[31:16] <= (parameter_count > 0) ? {8'h00, parameter_data[7:0]} : 16'h0000;
      packet_ready <= 1'b1;
      state <= 4'd1;
    end else if (busy) begin
      packet_ready <= 1'b0;
      if (state == 4'd5) begin 
        busy <= 1'b0; 
        state <= 4'd0; 
      end
      else state <= state + 1'b1;
    end
  end
endmodule

module kogge_stone_adder #(
  parameter WIDTH = 32
)(
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  input wire cin,
  output wire [WIDTH-1:0] sum,
  output wire cout
);
  
  wire [WIDTH-1:0] g, p;
  wire [WIDTH-1:0] g1, p1;
  wire [WIDTH-1:0] g2, p2;
  wire [WIDTH-1:0] g3, p3;
  wire [WIDTH-1:0] g4, p4;
  wire [WIDTH-1:0] g5, p5;
  
  // Generate and propagate signals
  assign g = a & b;
  assign p = a ^ b;
  
  // First level
  assign g1[0] = g[0];
  assign p1[0] = p[0];
  genvar i;
  generate
    for (i = 1; i < WIDTH; i = i + 1) begin : level1
      assign g1[i] = g[i] | (p[i] & g[i-1]);
      assign p1[i] = p[i] & p[i-1];
    end
  endgenerate
  
  // Second level
  assign g2[1:0] = g1[1:0];
  assign p2[1:0] = p1[1:0];
  generate
    for (i = 2; i < WIDTH; i = i + 1) begin : level2
      assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
      assign p2[i] = p1[i] & p1[i-2];
    end
  endgenerate
  
  // Third level
  assign g3[3:0] = g2[3:0];
  assign p3[3:0] = p2[3:0];
  generate
    for (i = 4; i < WIDTH; i = i + 1) begin : level3
      assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
      assign p3[i] = p2[i] & p2[i-4];
    end
  endgenerate
  
  // Fourth level
  assign g4[7:0] = g3[7:0];
  assign p4[7:0] = p3[7:0];
  generate
    for (i = 8; i < WIDTH; i = i + 1) begin : level4
      assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
      assign p4[i] = p3[i] & p3[i-8];
    end
  endgenerate
  
  // Fifth level
  assign g5[15:0] = g4[15:0];
  assign p5[15:0] = p4[15:0];
  generate
    for (i = 16; i < WIDTH; i = i + 1) begin : level5
      assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
      assign p5[i] = p4[i] & p4[i-16];
    end
  endgenerate
  
  // Final sum computation
  assign sum[0] = p[0] ^ cin;
  generate
    for (i = 1; i < WIDTH; i = i + 1) begin : sum_gen
      assign sum[i] = p[i] ^ g5[i-1];
    end
  endgenerate
  
  assign cout = g5[WIDTH-1];
endmodule