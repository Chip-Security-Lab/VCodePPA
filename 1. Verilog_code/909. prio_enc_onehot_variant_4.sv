//SystemVerilog
module prio_enc_onehot #(
  parameter W = 5
)(
  input  [W-1:0] req_onehot,
  output [W-1:0] enc_out
);

  // 流水线寄存器
  reg [$clog2(W)-1:0] pos_reg;
  reg valid_reg;
  
  // 优先级检测逻辑
  wire [$clog2(W)-1:0] next_pos;
  wire next_valid;
  
  // 实例化优先级检测子模块
  priority_detection #(
    .WIDTH(W)
  ) priority_detector (
    .req_onehot      (req_onehot),
    .has_valid_bit   (next_valid),
    .highest_bit_pos (next_pos)
  );

  // 流水线寄存器更新
  always @(*) begin
    pos_reg = next_pos;
    valid_reg = next_valid;
  end

  // 实例化编码器子模块
  encoder_to_onehot #(
    .WIDTH(W)
  ) encoder (
    .has_valid_bit   (valid_reg),
    .highest_bit_pos (pos_reg),
    .enc_out         (enc_out)
  );

endmodule

module priority_detection #(
  parameter WIDTH = 5
)(
  input  [WIDTH-1:0] req_onehot,
  output             has_valid_bit,
  output [$clog2(WIDTH)-1:0] highest_bit_pos
);

  // 优化的优先级检测逻辑
  wire [WIDTH-1:0] valid_mask;
  wire [$clog2(WIDTH)-1:0] pos_array [0:WIDTH-1];
  
  // 生成位置数组
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : pos_gen
      assign pos_array[i] = i[$clog2(WIDTH)-1:0];
    end
  endgenerate
  
  // 优化的最高优先级位检测
  assign valid_mask = req_onehot & ~(req_onehot - 1);
  assign has_valid_bit = |req_onehot;
  
  // 优化的多路选择器
  wire [$clog2(WIDTH)-1:0] selected_pos;
  assign selected_pos = valid_mask[0] ? pos_array[0] :
                       valid_mask[1] ? pos_array[1] :
                       valid_mask[2] ? pos_array[2] :
                       valid_mask[3] ? pos_array[3] :
                       valid_mask[4] ? pos_array[4] : 0;
  
  assign highest_bit_pos = selected_pos;

endmodule

module encoder_to_onehot #(
  parameter WIDTH = 5
)(
  input              has_valid_bit,
  input  [$clog2(WIDTH)-1:0] highest_bit_pos,
  output [WIDTH-1:0] enc_out
);

  // 优化的one-hot编码生成
  wire [WIDTH-1:0] encoded;
  
  // 使用移位操作生成one-hot编码
  assign encoded = has_valid_bit ? (1'b1 << highest_bit_pos) : {WIDTH{1'b0}};
  assign enc_out = encoded;

endmodule