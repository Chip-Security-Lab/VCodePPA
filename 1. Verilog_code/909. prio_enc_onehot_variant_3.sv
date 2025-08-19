//SystemVerilog
module prio_enc_onehot #(parameter W=8)(
  input [W-1:0] req_onehot,
  output [W-1:0] enc_out
);

  // 优化方法:
  // 1. 直接使用组合逻辑和移位运算符
  // 2. 消除临时变量enc_temp
  // 3. 使用优先级逻辑避免多余的case语句
  // 4. 通过位操作优化固定移位实现
  
  reg [W-1:0] encoded_result;
  
  always @(*) begin
    encoded_result = {W{1'b0}}; // 默认值为0
    
    // 优先级编码器 - 使用更高效的优先级逻辑
    // 按位位置反向扫描以保持原始优先级
    if (req_onehot[7] && W > 7) encoded_result = {{(W-8){1'b0}}, 8'b1000_0000};
    else if (req_onehot[6] && W > 6) encoded_result = {{(W-7){1'b0}}, 7'b100_0000, 1'b0};
    else if (req_onehot[5] && W > 5) encoded_result = {{(W-6){1'b0}}, 6'b10_0000, 2'b0};
    else if (req_onehot[4] && W > 4) encoded_result = {{(W-5){1'b0}}, 5'b1_0000, 3'b0};
    else if (req_onehot[3] && W > 3) encoded_result = {{(W-4){1'b0}}, 4'b1000, 4'b0};
    else if (req_onehot[2] && W > 2) encoded_result = {{(W-3){1'b0}}, 3'b100, 5'b0};
    else if (req_onehot[1] && W > 1) encoded_result = {{(W-2){1'b0}}, 2'b10, 6'b0};
    else if (req_onehot[0]) encoded_result = {{(W-1){1'b0}}, 1'b1, 7'b0};
  end
  
  // 最终输出
  assign enc_out = encoded_result;
  
endmodule