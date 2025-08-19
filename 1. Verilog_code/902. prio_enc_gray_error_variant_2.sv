//SystemVerilog
// IEEE 1364-2005 Verilog
module prio_enc_gray_error #(parameter N=8)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] gray_out,
  output reg error
);

  wire [$clog2(N)-1:0] bin_out;
  wire req_valid;
  
  // 并行前缀优先编码器实现
  prio_enc_parallel_prefix #(
    .N(N)
  ) prefix_encoder (
    .req(req),
    .bin_out(bin_out),
    .valid(req_valid)
  );
  
  // 二进制转格雷码
  always @(*) begin
    gray_out = {bin_out[$clog2(N)-1], bin_out[$clog2(N)-2:0] ^ bin_out[$clog2(N)-1:1]};
  end
  
  // 错误信号生成
  always @(*) begin
    error = ~req_valid;
  end

endmodule

// 并行前缀优先编码器子模块
module prio_enc_parallel_prefix #(parameter N=8)(
  input [N-1:0] req,
  output [$clog2(N)-1:0] bin_out,
  output valid
);
  
  // 中间信号定义
  wire [N-1:0] priority_vector;
  wire [N-1:0] one_hot;
  
  // 第一阶段：生成有效信号
  assign valid = |req;
  
  // 第二阶段：并行前缀计算
  // 使用并行前缀结构计算优先级向量
  generate
    if (N == 8) begin: gen_8bit
      // 第一级前缀
      wire [7:0] level1;
      assign level1[0] = req[0];
      assign level1[1] = req[1];
      assign level1[2] = req[2];
      assign level1[3] = req[3];
      assign level1[4] = req[4];
      assign level1[5] = req[5];
      assign level1[6] = req[6];
      assign level1[7] = req[7];
      
      // 第二级前缀
      wire [7:0] level2;
      assign level2[0] = level1[0];
      assign level2[1] = level1[1] | level1[0];
      assign level2[2] = level1[2];
      assign level2[3] = level1[3] | level1[2];
      assign level2[4] = level1[4];
      assign level2[5] = level1[5] | level1[4];
      assign level2[6] = level1[6];
      assign level2[7] = level1[7] | level1[6];
      
      // 第三级前缀
      wire [7:0] level3;
      assign level3[0] = level2[0];
      assign level3[1] = level2[1];
      assign level3[2] = level2[2] | level2[0];
      assign level3[3] = level2[3] | level2[1];
      assign level3[4] = level2[4];
      assign level3[5] = level2[5];
      assign level3[6] = level2[6] | level2[4];
      assign level3[7] = level2[7] | level2[5];
      
      // 最终前缀级
      assign priority_vector[0] = level3[0];
      assign priority_vector[1] = level3[1];
      assign priority_vector[2] = level3[2];
      assign priority_vector[3] = level3[3];
      assign priority_vector[4] = level3[4] | level3[0];
      assign priority_vector[5] = level3[5] | level3[1];
      assign priority_vector[6] = level3[6] | level3[2];
      assign priority_vector[7] = level3[7] | level3[3];
    end
  endgenerate
  
  // 第三阶段：优先级向量转换为one-hot编码
  assign one_hot[0] = req[0];
  genvar i;
  generate
    for (i = 1; i < N; i = i + 1) begin: gen_one_hot
      assign one_hot[i] = req[i] & ~priority_vector[i-1];
    end
  endgenerate
  
  // 第四阶段：one-hot编码转换为二进制编码
  one_hot_to_binary #(
    .N(N)
  ) encoder (
    .one_hot(one_hot),
    .binary(bin_out)
  );
  
endmodule

// one-hot到二进制转换器
module one_hot_to_binary #(parameter N=8)(
  input [N-1:0] one_hot,
  output reg [$clog2(N)-1:0] binary
);
  
  integer j;
  always @(*) begin
    binary = {$clog2(N){1'b0}};
    for (j = 0; j < N; j = j + 1) begin
      if (one_hot[j]) begin
        binary = binary | j[$clog2(N)-1:0];
      end
    end
  end
  
endmodule