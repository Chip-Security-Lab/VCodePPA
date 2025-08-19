//SystemVerilog
module sync_var_rotation_shifter (
  input wire clk,
  input wire rst_n,
  input wire [7:0] data,
  input wire [2:0] rot_amount,
  input wire rot_direction, // 0=left, 1=right
  output reg [7:0] rotated_data
);

  wire [7:0] right_rotated_result;
  wire [7:0] left_rotated_result;
  wire [2:0] right_sub_amt;
  wire [2:0] left_sub_amt;

  parallel_prefix_subtractor_8 u_pps_right (
    .a      (8'd8),
    .b      ({5'd0, rot_amount}),
    .diff   (right_sub_amt)
  );

  parallel_prefix_subtractor_8 u_pps_left (
    .a      (8'd8),
    .b      ({5'd0, rot_amount}),
    .diff   (left_sub_amt)
  );

  reg [7:0] right_rotated_result_reg;
  reg [7:0] left_rotated_result_reg;

  always @(*) begin
    if (rot_amount == 3'd0) begin
      right_rotated_result_reg = data;
    end else begin
      right_rotated_result_reg = (data >> rot_amount) | (data << right_sub_amt);
    end
  end

  always @(*) begin
    if (rot_amount == 3'd0) begin
      left_rotated_result_reg = data;
    end else begin
      left_rotated_result_reg = (data << rot_amount) | (data >> left_sub_amt);
    end
  end

  assign right_rotated_result = right_rotated_result_reg;
  assign left_rotated_result  = left_rotated_result_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rotated_data <= 8'h00;
    end else begin
      if (rot_direction) begin
        rotated_data <= right_rotated_result;
      end else begin
        rotated_data <= left_rotated_result;
      end
    end
  end

endmodule

module parallel_prefix_subtractor_8 (
  input  wire [7:0] a,
  input  wire [7:0] b,
  output wire [2:0] diff
);
  // Parallel Prefix Subtractor for 3-bit result: diff = a[2:0] - b[2:0]
  wire [2:0] g, p, c, b_bit, a_bit;
  assign a_bit = a[2:0];
  assign b_bit = b[2:0];

  assign g[0] = a_bit[0] & ~b_bit[0];
  assign p[0] = ~(a_bit[0] ^ b_bit[0]);

  assign g[1] = a_bit[1] & ~b_bit[1];
  assign p[1] = ~(a_bit[1] ^ b_bit[1]);

  assign g[2] = a_bit[2] & ~b_bit[2];
  assign p[2] = ~(a_bit[2] ^ b_bit[2]);

  assign c[0] = 1'b1; // Borrow in is 1 for subtraction (two's complement)
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);

  assign diff[0] = a_bit[0] ^ b_bit[0] ^ ~c[0];
  assign diff[1] = a_bit[1] ^ b_bit[1] ^ ~c[1];
  assign diff[2] = a_bit[2] ^ b_bit[2] ^ ~c[2];

endmodule