module sign_extension_shifter (
  input [15:0] input_data,
  input [3:0] shift_right,
  input sign_extend,
  output [15:0] result
);
  wire sign_bit = input_data[15];
  
  // 使用查找表处理不同的移位量
  reg [15:0] shifted;
  always @(*) begin
    case(shift_right)
      4'd0: shifted = input_data;
      4'd1: shifted = {1'b0, input_data[15:1]};
      4'd2: shifted = {2'b0, input_data[15:2]};
      4'd3: shifted = {3'b0, input_data[15:3]};
      4'd4: shifted = {4'b0, input_data[15:4]};
      4'd5: shifted = {5'b0, input_data[15:5]};
      4'd6: shifted = {6'b0, input_data[15:6]};
      4'd7: shifted = {7'b0, input_data[15:7]};
      4'd8: shifted = {8'b0, input_data[15:8]};
      4'd9: shifted = {9'b0, input_data[15:9]};
      4'd10: shifted = {10'b0, input_data[15:10]};
      4'd11: shifted = {11'b0, input_data[15:11]};
      4'd12: shifted = {12'b0, input_data[15:12]};
      4'd13: shifted = {13'b0, input_data[15:13]};
      4'd14: shifted = {14'b0, input_data[15:14]};
      4'd15: shifted = {15'b0, input_data[15]};
      default: shifted = input_data;
    endcase
  end
  
  // 符号扩展
  reg [15:0] sign_extended;
  always @(*) begin
    case(shift_right)
      4'd0: sign_extended = input_data;
      4'd1: sign_extended = sign_bit ? {1'b1, input_data[15:1]} : {1'b0, input_data[15:1]};
      4'd2: sign_extended = sign_bit ? {2'b11, input_data[15:2]} : {2'b00, input_data[15:2]};
      4'd3: sign_extended = sign_bit ? {3'b111, input_data[15:3]} : {3'b000, input_data[15:3]};
      4'd4: sign_extended = sign_bit ? {4'b1111, input_data[15:4]} : {4'b0000, input_data[15:4]};
      4'd5: sign_extended = sign_bit ? {5'b11111, input_data[15:5]} : {5'b00000, input_data[15:5]};
      4'd6: sign_extended = sign_bit ? {6'b111111, input_data[15:6]} : {6'b000000, input_data[15:6]};
      4'd7: sign_extended = sign_bit ? {7'b1111111, input_data[15:7]} : {7'b0000000, input_data[15:7]};
      4'd8: sign_extended = sign_bit ? {8'b11111111, input_data[15:8]} : {8'b00000000, input_data[15:8]};
      4'd9: sign_extended = sign_bit ? {9'b111111111, input_data[15:9]} : {9'b000000000, input_data[15:9]};
      4'd10: sign_extended = sign_bit ? {10'b1111111111, input_data[15:10]} : {10'b0000000000, input_data[15:10]};
      4'd11: sign_extended = sign_bit ? {11'b11111111111, input_data[15:11]} : {11'b00000000000, input_data[15:11]};
      4'd12: sign_extended = sign_bit ? {12'b111111111111, input_data[15:12]} : {12'b000000000000, input_data[15:12]};
      4'd13: sign_extended = sign_bit ? {13'b1111111111111, input_data[15:13]} : {13'b0000000000000, input_data[15:13]};
      4'd14: sign_extended = sign_bit ? {14'b11111111111111, input_data[15:14]} : {14'b00000000000000, input_data[15:14]};
      4'd15: sign_extended = sign_bit ? {15'b111111111111111, input_data[15]} : {15'b000000000000000, input_data[15]};
      default: sign_extended = input_data;
    endcase
  end
  
  // 根据sign_extend选择结果
  assign result = sign_extend ? sign_extended : shifted;
endmodule