//SystemVerilog
module parity_calculator #(
  parameter WIDTH = 8
)(
  input [WIDTH-1:0] data,
  output parity
);
  // 使用异或树实现奇偶校验
  wire [WIDTH/2-1:0] xor_level1;
  wire [WIDTH/4-1:0] xor_level2;
  wire [WIDTH/8-1:0] xor_level3;
  
  // 第一级异或
  genvar i;
  generate
    for(i = 0; i < WIDTH/2; i = i + 1) begin
      assign xor_level1[i] = data[2*i] ^ data[2*i+1];
    end
  endgenerate
  
  // 第二级异或
  generate
    for(i = 0; i < WIDTH/4; i = i + 1) begin
      assign xor_level2[i] = xor_level1[2*i] ^ xor_level1[2*i+1];
    end
  endgenerate
  
  // 第三级异或
  generate
    for(i = 0; i < WIDTH/8; i = i + 1) begin
      assign xor_level3[i] = xor_level2[2*i] ^ xor_level2[2*i+1];
    end
  endgenerate
  
  // 最终输出
  assign parity = ^xor_level3;

endmodule

module even_parity_gen #(
  parameter DATA_WIDTH = 8
)(
  input [DATA_WIDTH-1:0] data_in,
  output parity_out
);
  
  parity_calculator #(
    .WIDTH(DATA_WIDTH)
  ) parity_calc (
    .data(data_in),
    .parity(parity_out)
  );

endmodule