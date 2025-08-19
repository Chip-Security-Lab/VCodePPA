module priority_shifter (
  input [15:0] in_data,
  input [15:0] priority_mask,
  output [15:0] out_data
);
  // 使用优先级编码器找到最高优先级
  reg [3:0] highest_priority;
  
  always @(*) begin
    if (priority_mask[15]) highest_priority = 4'd15;
    else if (priority_mask[14]) highest_priority = 4'd14;
    else if (priority_mask[13]) highest_priority = 4'd13;
    else if (priority_mask[12]) highest_priority = 4'd12;
    else if (priority_mask[11]) highest_priority = 4'd11;
    else if (priority_mask[10]) highest_priority = 4'd10;
    else if (priority_mask[9]) highest_priority = 4'd9;
    else if (priority_mask[8]) highest_priority = 4'd8;
    else if (priority_mask[7]) highest_priority = 4'd7;
    else if (priority_mask[6]) highest_priority = 4'd6;
    else if (priority_mask[5]) highest_priority = 4'd5;
    else if (priority_mask[4]) highest_priority = 4'd4;
    else if (priority_mask[3]) highest_priority = 4'd3;
    else if (priority_mask[2]) highest_priority = 4'd2;
    else if (priority_mask[1]) highest_priority = 4'd1;
    else if (priority_mask[0]) highest_priority = 4'd0;
    else highest_priority = 4'd0;
  end
  
  // 使用查找表处理不同的移位量
  reg [15:0] shifted_data;
  always @(*) begin
    case(highest_priority)
      4'd0: shifted_data = in_data;
      4'd1: shifted_data = in_data << 1;
      4'd2: shifted_data = in_data << 2;
      4'd3: shifted_data = in_data << 3;
      4'd4: shifted_data = in_data << 4;
      4'd5: shifted_data = in_data << 5;
      4'd6: shifted_data = in_data << 6;
      4'd7: shifted_data = in_data << 7;
      4'd8: shifted_data = in_data << 8;
      4'd9: shifted_data = in_data << 9;
      4'd10: shifted_data = in_data << 10;
      4'd11: shifted_data = in_data << 11;
      4'd12: shifted_data = in_data << 12;
      4'd13: shifted_data = in_data << 13;
      4'd14: shifted_data = in_data << 14;
      4'd15: shifted_data = in_data << 15;
      default: shifted_data = in_data;
    endcase
  end
  
  assign out_data = shifted_data;
endmodule