module nibble_rotation_shifter (
  input [15:0] data,
  input [1:0] nibble_sel, // 00=all, 01=upper byte, 10=lower byte, 11=specific nibble
  input [1:0] specific_nibble, // Used when nibble_sel=11
  input [1:0] rotate_amount,
  output [15:0] result
);
  // 分解数据为nibble
  wire [3:0] nibble0 = data[3:0];
  wire [3:0] nibble1 = data[7:4];
  wire [3:0] nibble2 = data[11:8];
  wire [3:0] nibble3 = data[15:12];
  
  // 旋转nibble0
  wire [3:0] rotated_nibble0 = (rotate_amount == 2'b00) ? nibble0 :
                              (rotate_amount == 2'b01) ? {nibble0[2:0], nibble0[3]} :
                              (rotate_amount == 2'b10) ? {nibble0[1:0], nibble0[3:2]} :
                              {nibble0[0], nibble0[3:1]};
  
  // 旋转nibble1
  wire [3:0] rotated_nibble1 = (rotate_amount == 2'b00) ? nibble1 :
                              (rotate_amount == 2'b01) ? {nibble1[2:0], nibble1[3]} :
                              (rotate_amount == 2'b10) ? {nibble1[1:0], nibble1[3:2]} :
                              {nibble1[0], nibble1[3:1]};
  
  // 旋转nibble2
  wire [3:0] rotated_nibble2 = (rotate_amount == 2'b00) ? nibble2 :
                              (rotate_amount == 2'b01) ? {nibble2[2:0], nibble2[3]} :
                              (rotate_amount == 2'b10) ? {nibble2[1:0], nibble2[3:2]} :
                              {nibble2[0], nibble2[3:1]};
  
  // 旋转nibble3
  wire [3:0] rotated_nibble3 = (rotate_amount == 2'b00) ? nibble3 :
                              (rotate_amount == 2'b01) ? {nibble3[2:0], nibble3[3]} :
                              (rotate_amount == 2'b10) ? {nibble3[1:0], nibble3[3:2]} :
                              {nibble3[0], nibble3[3:1]};
  
  // 根据选择生成结果
  reg [15:0] result_reg;
  always @(*) begin
    case (nibble_sel)
      2'b00: result_reg = {rotated_nibble3, rotated_nibble2, rotated_nibble1, rotated_nibble0};
      2'b01: result_reg = {rotated_nibble3, rotated_nibble2, nibble1, nibble0};
      2'b10: result_reg = {nibble3, nibble2, rotated_nibble1, rotated_nibble0};
      2'b11: begin
        case (specific_nibble)
          2'b00: result_reg = {nibble3, nibble2, nibble1, rotated_nibble0};
          2'b01: result_reg = {nibble3, nibble2, rotated_nibble1, nibble0};
          2'b10: result_reg = {nibble3, rotated_nibble2, nibble1, nibble0};
          2'b11: result_reg = {rotated_nibble3, nibble2, nibble1, nibble0};
          default: result_reg = data;
        endcase
      end
      default: result_reg = data;
    endcase
  end
  
  assign result = result_reg;
endmodule