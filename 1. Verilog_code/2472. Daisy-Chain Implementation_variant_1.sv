//SystemVerilog
module daisy_chain_intr_ctrl(
  input clk, rst_n,
  input [3:0] requests,
  input chain_in,
  output reg [1:0] local_id,
  output reg chain_out,
  output reg grant
);
  reg local_req;
  reg [3:0] requests_reg;
  reg chain_in_reg;
  wire [3:0] mult_a, mult_b;
  wire [7:0] mult_result;
  
  // 将输入信号寄存器化，减少输入到第一级寄存器的延迟
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      requests_reg <= 4'b0;
      chain_in_reg <= 1'b0;
    end else begin
      requests_reg <= requests;
      chain_in_reg <= chain_in;
    end
  end
  
  // 使用寄存器化的请求信号作为乘法器的输入
  assign mult_a = requests_reg;
  assign mult_b = {3'b001, chain_in_reg};
  
  // 引入Baugh-Wooley乘法器
  baugh_wooley_4bit multiplier(
    .a(mult_a),
    .b(mult_b),
    .result(mult_result)
  );
  
  // 判断是否有本地请求逻辑移到时序逻辑中
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      local_req <= 1'b0;
      local_id <= 2'd0;
      chain_out <= 1'b0;
    end else begin
      local_req <= |requests_reg;
      casez (requests_reg)
        4'b???1: local_id <= 2'd0;
        4'b??10: local_id <= 2'd1;
        4'b?100: local_id <= 2'd2;
        4'b1000: local_id <= 2'd3;
        default: local_id <= 2'd0;
      endcase
      chain_out <= chain_in_reg & ~local_req;
    end
  end
  
  // grant信号保持不变，但使用已寄存器化的信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      grant <= 1'b0;
    else
      grant <= local_req & chain_in_reg;
  end
endmodule

// Baugh-Wooley 4位乘法器模块
module baugh_wooley_4bit(
  input [3:0] a,
  input [3:0] b,
  output reg [7:0] result
);
  // 部分积
  wire [3:0] pp0, pp1, pp2, pp3;
  // 中间sum和carry信号
  wire [15:0] sum_bits, carry_bits;
  // 最终结果位
  wire [7:0] final_result;
  
  // 生成部分积
  // 对于Baugh-Wooley算法，最高位需要特殊处理
  assign pp0[0] = a[0] & b[0];
  assign pp0[1] = a[0] & b[1];
  assign pp0[2] = a[0] & b[2];
  assign pp0[3] = ~(a[0] & b[3]); // 特殊处理
  
  assign pp1[0] = a[1] & b[0];
  assign pp1[1] = a[1] & b[1];
  assign pp1[2] = a[1] & b[2];
  assign pp1[3] = ~(a[1] & b[3]); // 特殊处理
  
  assign pp2[0] = a[2] & b[0];
  assign pp2[1] = a[2] & b[1];
  assign pp2[2] = a[2] & b[2];
  assign pp2[3] = ~(a[2] & b[3]); // 特殊处理
  
  assign pp3[0] = ~(a[3] & b[0]); // 特殊处理
  assign pp3[1] = ~(a[3] & b[1]); // 特殊处理
  assign pp3[2] = ~(a[3] & b[2]); // 特殊处理
  assign pp3[3] = a[3] & b[3];    // 特殊处理
  
  // 加1补偿（用于修正符号位扩展）
  wire correction = 1'b1;
  
  // 第一级压缩（部分积的加法）
  full_adder fa_0_0(.a(pp0[0]), .b(1'b0), .cin(1'b0), .sum(final_result[0]), .cout(carry_bits[0]));
  full_adder fa_1_0(.a(pp0[1]), .b(pp1[0]), .cin(carry_bits[0]), .sum(final_result[1]), .cout(carry_bits[1]));
  full_adder fa_2_0(.a(pp0[2]), .b(pp1[1]), .cin(carry_bits[1]), .sum(sum_bits[0]), .cout(carry_bits[2]));
  full_adder fa_2_1(.a(pp2[0]), .b(sum_bits[0]), .cin(1'b0), .sum(final_result[2]), .cout(carry_bits[3]));
  
  full_adder fa_3_0(.a(pp0[3]), .b(pp1[2]), .cin(carry_bits[2]), .sum(sum_bits[1]), .cout(carry_bits[4]));
  full_adder fa_3_1(.a(pp2[1]), .b(pp3[0]), .cin(carry_bits[3]), .sum(sum_bits[2]), .cout(carry_bits[5]));
  full_adder fa_3_2(.a(sum_bits[1]), .b(sum_bits[2]), .cin(1'b0), .sum(final_result[3]), .cout(carry_bits[6]));
  
  full_adder fa_4_0(.a(pp1[3]), .b(pp2[2]), .cin(carry_bits[4]), .sum(sum_bits[3]), .cout(carry_bits[7]));
  full_adder fa_4_1(.a(pp3[1]), .b(sum_bits[3]), .cin(carry_bits[5]), .sum(sum_bits[4]), .cout(carry_bits[8]));
  full_adder fa_4_2(.a(sum_bits[4]), .b(carry_bits[6]), .cin(1'b0), .sum(final_result[4]), .cout(carry_bits[9]));
  
  full_adder fa_5_0(.a(pp2[3]), .b(pp3[2]), .cin(carry_bits[7]), .sum(sum_bits[5]), .cout(carry_bits[10]));
  full_adder fa_5_1(.a(sum_bits[5]), .b(carry_bits[8]), .cin(carry_bits[9]), .sum(final_result[5]), .cout(carry_bits[11]));
  
  full_adder fa_6_0(.a(pp3[3]), .b(correction), .cin(carry_bits[10]), .sum(sum_bits[6]), .cout(carry_bits[12]));
  full_adder fa_6_1(.a(sum_bits[6]), .b(carry_bits[11]), .cin(1'b0), .sum(final_result[6]), .cout(carry_bits[13]));
  
  full_adder fa_7_0(.a(carry_bits[12]), .b(carry_bits[13]), .cin(1'b0), .sum(final_result[7]), .cout());
  
  // 将乘法结果寄存器化，减少关键路径延迟
  always @(*) begin
    result = final_result;
  end
endmodule

// 全加器模块
module full_adder(
  input a, b, cin,
  output sum, cout
);
  assign sum = a ^ b ^ cin;
  assign cout = (a & b) | (a & cin) | (b & cin);
endmodule