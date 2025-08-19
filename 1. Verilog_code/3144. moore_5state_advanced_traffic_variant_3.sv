//SystemVerilog
module moore_5state_advanced_traffic_pipeline(
  input  clk,
  input  rst,
  output reg [2:0] light
);
  reg [2:0] state_stage1, state_stage2, next_state_stage1, next_state_stage2;
  reg [2:0] multiplier_a, multiplier_b;
  wire [5:0] product;
  
  localparam G   = 3'b000,
             GY  = 3'b001,
             Y   = 3'b010,
             R   = 3'b011,
             RY  = 3'b100;

  // Wallace树乘法器实现 - 3位乘法
  // 部分积生成
  wire [2:0] pp0, pp1, pp2;
  assign pp0 = multiplier_b[0] ? multiplier_a : 3'b000;
  assign pp1 = multiplier_b[1] ? {multiplier_a, 1'b0} : 4'b0000;
  assign pp2 = multiplier_b[2] ? {multiplier_a, 2'b00} : 5'b00000;
  
  // Wallace树压缩
  wire [5:0] s1, c1;  // 第一级加法器输出
  wire [5:0] s2, c2;  // 第二级加法器输出
  
  // 第一级压缩
  assign s1[0] = pp0[0];
  assign c1[0] = 1'b0;
  
  full_adder fa1_1(pp0[1], pp1[0], 1'b0, s1[1], c1[1]);
  full_adder fa1_2(pp0[2], pp1[1], pp2[0], s1[2], c1[2]);
  full_adder fa1_3(1'b0, pp1[2], pp2[1], s1[3], c1[3]);
  assign s1[4] = pp2[2];
  assign c1[4] = 1'b0;
  assign s1[5] = 1'b0;
  assign c1[5] = 1'b0;
  
  // 第二级压缩 (最终加法)
  assign s2[0] = s1[0];
  half_adder ha2_1(s1[1], c1[0], s2[1], c2[1]);
  full_adder fa2_1(s1[2], c1[1], c2[1], s2[2], c2[2]);
  full_adder fa2_2(s1[3], c1[2], c2[2], s2[3], c2[3]);
  full_adder fa2_3(s1[4], c1[3], c2[3], s2[4], c2[4]);
  full_adder fa2_4(s1[5], c1[4], c2[4], s2[5], c2[5]);
  
  // 最终结果
  assign product = s2;

  // Stage 1: State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= G;
      multiplier_a <= 3'b001;
      multiplier_b <= 3'b001;
    end
    else begin
      state_stage1 <= next_state_stage1;
      
      // 根据当前状态更新乘法器操作数
      case (state_stage1)
        G:   begin
               multiplier_a <= 3'b001;
               multiplier_b <= 3'b010;
             end
        GY:  begin
               multiplier_a <= 3'b010;
               multiplier_b <= 3'b010;
             end
        Y:   begin
               multiplier_a <= 3'b011;
               multiplier_b <= 3'b001;
             end
        R:   begin
               multiplier_a <= 3'b010;
               multiplier_b <= 3'b011;
             end
        RY:  begin
               multiplier_a <= 3'b001;
               multiplier_b <= 3'b001;
             end
        default: begin
               multiplier_a <= 3'b001;
               multiplier_b <= 3'b001;
             end
      endcase
    end
  end

  // Stage 2: Next State Logic
  always @* begin
    case (state_stage1)
      G:   next_state_stage1 = GY;
      GY:  next_state_stage1 = Y;
      Y:   next_state_stage1 = R;
      R:   next_state_stage1 = RY;
      RY:  next_state_stage1 = G;
      default: next_state_stage1 = G;
    endcase
  end

  // Stage 3: State Register (Pipeline Stage 2)
  always @(posedge clk or posedge rst) begin
    if (rst) state_stage2 <= G;
    else     state_stage2 <= next_state_stage1;
  end

  // Stage 4: Light Output Logic
  always @* begin
    case (state_stage2)
      G:   light = 3'b100;
      GY:  light = 3'b110;
      Y:   light = 3'b010;
      R:   light = 3'b001;
      RY:  light = 3'b011;
      default: light = 3'b100;
    endcase
  end
endmodule

// 全加器子模块
module full_adder(
  input a, b, cin,
  output sum, cout
);
  assign sum = a ^ b ^ cin;
  assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// 半加器子模块
module half_adder(
  input a, b,
  output sum, cout
);
  assign sum = a ^ b;
  assign cout = a & b;
endmodule