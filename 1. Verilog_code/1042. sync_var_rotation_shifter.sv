module sync_var_rotation_shifter (
  input clk, rst_n,
  input [7:0] data,
  input [2:0] rot_amount,
  input rot_direction, // 0=left, 1=right
  output reg [7:0] rotated_data
);
  reg [7:0] right_rotated, left_rotated;
  
  always @(*) begin
    // 右旋转的所有可能性
    case(rot_amount)
      3'd0: right_rotated = data;
      3'd1: right_rotated = {data[0], data[7:1]};
      3'd2: right_rotated = {data[1:0], data[7:2]};
      3'd3: right_rotated = {data[2:0], data[7:3]};
      3'd4: right_rotated = {data[3:0], data[7:4]};
      3'd5: right_rotated = {data[4:0], data[7:5]};
      3'd6: right_rotated = {data[5:0], data[7:6]};
      3'd7: right_rotated = {data[6:0], data[7]};
      default: right_rotated = data;
    endcase
    
    // 左旋转的所有可能性
    case(rot_amount)
      3'd0: left_rotated = data;
      3'd1: left_rotated = {data[6:0], data[7]};
      3'd2: left_rotated = {data[5:0], data[7:6]};
      3'd3: left_rotated = {data[4:0], data[7:5]};
      3'd4: left_rotated = {data[3:0], data[7:4]};
      3'd5: left_rotated = {data[2:0], data[7:3]};
      3'd6: left_rotated = {data[1:0], data[7:2]};
      3'd7: left_rotated = {data[0], data[7:1]};
      default: left_rotated = data;
    endcase
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rotated_data <= 8'h0;
    else if (rot_direction) // 右旋转
      rotated_data <= right_rotated;
    else // 左旋转
      rotated_data <= left_rotated;
  end
endmodule