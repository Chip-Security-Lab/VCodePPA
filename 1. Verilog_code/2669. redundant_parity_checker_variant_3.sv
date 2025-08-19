//SystemVerilog
// SystemVerilog
// 顶层模块
module redundant_parity_checker(
  input [7:0] data_in,
  input ext_parity,
  output error_detected
);
  // 内部信号
  wire parity_a, parity_b, parity_agreement;
  
  // 子模块实例化
  parity_generator_mult gen_a (
    .data(data_in),
    .parity(parity_a)
  );
  
  parity_generator_lut gen_b (
    .data(data_in),
    .parity(parity_b)
  );
  
  parity_comparator comparator (
    .parity_a(parity_a),
    .parity_b(parity_b),
    .ext_parity(ext_parity),
    .error_detected(error_detected)
  );
endmodule

// 子模块1: 使用带符号乘法的奇偶校验生成器
module parity_generator_mult(
  input [7:0] data,
  output parity
);
  // 使用带符号乘法来计算奇偶校验
  // 该技术利用乘法的分布性质计算各位的异或
  wire signed [15:0] mult_result;
  wire [7:0] ones_vector;
  
  assign ones_vector = 8'b01010101; // 交替的1和0模式
  assign mult_result = $signed(data) * $signed(ones_vector);
  assign parity = ^mult_result[7:0]; // 取结果低8位的奇偶校验
endmodule

// 子模块2: 查找表优化的奇偶校验生成器
module parity_generator_lut(
  input [7:0] data,
  output reg parity
);
  // 使用查找表方法优化的奇偶校验计算
  reg [3:0] lut_index;
  reg [1:0] partial_parity;
  
  always @(*) begin
    lut_index = {data[7], data[5], data[3], data[1]};
    
    // 基于查找表计算部分奇偶校验
    case(lut_index)
      4'b0000: partial_parity = 2'b00;
      4'b0001: partial_parity = 2'b01;
      4'b0010: partial_parity = 2'b01;
      4'b0011: partial_parity = 2'b00;
      4'b0100: partial_parity = 2'b01;
      4'b0101: partial_parity = 2'b00;
      4'b0110: partial_parity = 2'b00;
      4'b0111: partial_parity = 2'b01;
      4'b1000: partial_parity = 2'b01;
      4'b1001: partial_parity = 2'b00;
      4'b1010: partial_parity = 2'b00;
      4'b1011: partial_parity = 2'b01;
      4'b1100: partial_parity = 2'b00;
      4'b1101: partial_parity = 2'b01;
      4'b1110: partial_parity = 2'b01;
      4'b1111: partial_parity = 2'b00;
    endcase
    
    // 与剩余位计算最终奇偶校验
    parity = partial_parity[0] ^ partial_parity[1] ^ data[6] ^ data[4] ^ data[2] ^ data[0];
  end
endmodule

// 子模块3: 奇偶校验比较器
module parity_comparator(
  input parity_a,
  input parity_b,
  input ext_parity,
  output error_detected
);
  wire parity_agreement;
  
  // 比较两个内部生成的奇偶校验位
  assign parity_agreement = parity_a == parity_b;
  
  // 检测错误：如果内部奇偶校验一致但与外部奇偶校验不同
  assign error_detected = parity_agreement && (parity_a != ext_parity);
endmodule