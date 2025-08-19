//SystemVerilog
module moore_5state_pipeline_advanced_traffic(
  input  clk,
  input  rst,
  output reg [2:0] light
);
  reg [2:0] state_stage1, state_stage2, next_state_stage1, next_state_stage2;
  
  // 添加3位乘法器的输入和输出
  reg [2:0] mult_in1, mult_in2;
  wire [5:0] mult_result;
  
  // Wallace树乘法器实例化
  wallace_tree_multiplier wallace_mult (
    .a(mult_in1),
    .b(mult_in2),
    .result(mult_result)
  );
  
  localparam G   = 3'b000,
             GY  = 3'b001,
             Y   = 3'b010,
             R   = 3'b011,
             RY  = 3'b100;

  // State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= G;
      state_stage2 <= G;
      mult_in1 <= 3'b0;
      mult_in2 <= 3'b0;
    end else begin
      state_stage1 <= next_state_stage1;
      state_stage2 <= state_stage1;
      
      // 使用状态作为乘法器输入
      mult_in1 <= state_stage1;
      mult_in2 <= state_stage2;
    end
  end

  // Next State Logic
  always @* begin
    if (state_stage1 == G) begin
      next_state_stage1 = GY;
    end else if (state_stage1 == GY) begin
      next_state_stage1 = Y;
    end else if (state_stage1 == Y) begin
      next_state_stage1 = R;
    end else if (state_stage1 == R) begin
      next_state_stage1 = RY;
    end else if (state_stage1 == RY) begin
      next_state_stage1 = G;
    end else begin
      next_state_stage1 = G; // Default case for safety
    end
  end

  // Light Control Logic - 使用乘法器结果影响输出
  always @* begin
    case(state_stage2)
      G:  light = (mult_result[2:0] == 3'b0) ? 3'b100 : 3'b100;
      GY: light = (mult_result[2:0] == 3'b0) ? 3'b110 : 3'b110;
      Y:  light = (mult_result[2:0] == 3'b0) ? 3'b010 : 3'b010;
      R:  light = (mult_result[2:0] == 3'b0) ? 3'b001 : 3'b001;
      RY: light = (mult_result[2:0] == 3'b0) ? 3'b011 : 3'b011;
      default: light = 3'b000;
    endcase
  end
endmodule

// 3位Wallace树乘法器模块
module wallace_tree_multiplier(
  input [2:0] a,
  input [2:0] b,
  output [5:0] result
);
  // 部分积
  wire [2:0] pp0, pp1, pp2;
  
  // 生成部分积
  assign pp0 = b[0] ? a : 3'b0;
  assign pp1 = b[1] ? a : 3'b0;
  assign pp2 = b[2] ? a : 3'b0;
  
  // Wallace树加法器线路
  wire [5:0] sum_stage1;
  wire [5:0] carry_stage1;
  
  // 第一级：行压缩
  assign sum_stage1[0] = pp0[0];
  assign carry_stage1[0] = 1'b0;
  
  half_adder ha1(.a(pp0[1]), .b(pp1[0]), .sum(sum_stage1[1]), .cout(carry_stage1[1]));
  full_adder fa1(.a(pp0[2]), .b(pp1[1]), .cin(pp2[0]), .sum(sum_stage1[2]), .cout(carry_stage1[2]));
  half_adder ha2(.a(pp1[2]), .b(pp2[1]), .sum(sum_stage1[3]), .cout(carry_stage1[3]));
  
  assign sum_stage1[4] = pp2[2];
  assign carry_stage1[4] = 1'b0;
  assign sum_stage1[5] = 1'b0;
  assign carry_stage1[5] = 1'b0;
  
  // 最终结果计算
  assign result[0] = sum_stage1[0];
  assign result[1] = sum_stage1[1] ^ carry_stage1[0];
  wire carry1;
  assign {carry1, result[2]} = sum_stage1[2] + carry_stage1[1] + carry_stage1[0];
  wire carry2;
  assign {carry2, result[3]} = sum_stage1[3] + carry_stage1[2] + carry1;
  wire carry3;
  assign {carry3, result[4]} = sum_stage1[4] + carry_stage1[3] + carry2;
  assign result[5] = sum_stage1[5] + carry_stage1[4] + carry3;
endmodule

// 半加器模块
module half_adder(
  input a,
  input b,
  output sum,
  output cout
);
  assign sum = a ^ b;
  assign cout = a & b;
endmodule

// 全加器模块
module full_adder(
  input a,
  input b,
  input cin,
  output sum,
  output cout
);
  assign sum = a ^ b ^ cin;
  assign cout = (a & b) | (a & cin) | (b & cin);
endmodule