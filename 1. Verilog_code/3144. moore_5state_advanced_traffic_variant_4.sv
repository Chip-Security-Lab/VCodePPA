//SystemVerilog
module moore_5state_advanced_traffic(
  input  clk,
  input  rst,
  input  [2:0] a,
  input  [2:0] b,
  output reg [2:0] light,
  output [5:0] product
);
  reg [2:0] state, next_state;
  localparam G   = 3'b000,
             GY  = 3'b001,
             Y   = 3'b010,
             R   = 3'b011,
             RY  = 3'b100;

  // Wallace树乘法器
  wallace_multiplier_3bit mult_unit(
    .a(a),
    .b(b),
    .p(product)
  );

  always @(posedge clk or posedge rst) begin
    if (rst) state <= G;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      G:   next_state = GY;
      GY:  next_state = Y;
      Y:   next_state = R;
      R:   next_state = RY;
      RY:  next_state = G;
      default: next_state = G; // 默认状态
    endcase
  end

  always @* begin
    case (state)
      G:   light = 3'b100;
      GY:  light = 3'b110;
      Y:   light = 3'b010;
      R:   light = 3'b001;
      RY:  light = 3'b011;
      default: light = 3'b000; // 默认灯光状态
    endcase
  end
endmodule

module wallace_multiplier_3bit(
  input [2:0] a,
  input [2:0] b,
  output [5:0] p
);
  // 部分积生成
  wire [2:0] pp0, pp1, pp2;
  
  assign pp0 = a & {3{b[0]}};
  assign pp1 = a & {3{b[1]}};
  assign pp2 = a & {3{b[2]}};
  
  // 第一级压缩
  wire [3:0] s1, c1;
  wire temp1, temp2, temp3;
  
  // 第一位 - 只有pp0[0]，直接赋值
  assign p[0] = pp0[0];
  
  // 第二位 - pp0[1]和pp1[0]相加
  wire ha1_sum, ha1_cout;
  half_adder ha1(
    .a(pp0[1]),
    .b(pp1[0]),
    .sum(ha1_sum),
    .cout(ha1_cout)
  );
  assign s1[0] = ha1_sum;
  assign c1[0] = ha1_cout;
  
  // 第三位 - pp0[2], pp1[1], pp2[0]相加
  wire fa1_sum, fa1_cout;
  full_adder fa1(
    .a(pp0[2]),
    .b(pp1[1]),
    .cin(pp2[0]),
    .sum(fa1_sum),
    .cout(fa1_cout)
  );
  assign s1[1] = fa1_sum;
  assign c1[1] = fa1_cout;
  
  // 第四位 - pp1[2], pp2[1]相加
  wire ha2_sum, ha2_cout;
  half_adder ha2(
    .a(pp1[2]),
    .b(pp2[1]),
    .sum(ha2_sum),
    .cout(ha2_cout)
  );
  assign s1[2] = ha2_sum;
  assign c1[2] = ha2_cout;
  
  // 第五位 - 只有pp2[2]
  assign s1[3] = pp2[2];
  assign c1[3] = 1'b0;
  
  // 第二级压缩 (最终加法)
  assign p[1] = s1[0];
  
  wire ha3_sum, ha3_cout;
  half_adder ha3(
    .a(s1[1]),
    .b(c1[0]),
    .sum(ha3_sum),
    .cout(ha3_cout)
  );
  assign p[2] = ha3_sum;
  
  wire fa2_sum, fa2_cout;
  full_adder fa2(
    .a(s1[2]),
    .b(c1[1]),
    .cin(ha3_cout),
    .sum(fa2_sum),
    .cout(fa2_cout)
  );
  assign p[3] = fa2_sum;
  
  full_adder fa3(
    .a(s1[3]),
    .b(c1[2]),
    .cin(fa2_cout),
    .sum(p[4]),
    .cout(p[5])
  );
endmodule

module half_adder(
  input a,
  input b,
  output sum,
  output cout
);
  assign sum = a ^ b;
  assign cout = a & b;
endmodule

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