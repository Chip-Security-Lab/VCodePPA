//SystemVerilog
// IEEE 1364-2005
module prio_enc_parallel #(parameter N=16)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);

  // 并行前缀减法器实现
  wire [N-1:0] g, p;
  wire [N-1:0] carry;
  wire [N-1:0] mask;
  wire [N-1:0] lead_one;

  // 生成和传播信号
  genvar i;
  generate
    for (i=0; i<N; i=i+1) begin: gen_pp
      assign g[i] = ~req[i];
      assign p[i] = 1'b1;
    end
  endgenerate

  // 并行前缀树实现
  wire [N-1:0] g1, p1;
  wire [N-1:0] g2, p2;
  wire [N-1:0] g3, p3;
  wire [N-1:0] g4, p4;

  // 第一级前缀
  assign g1[0] = g[0];
  assign p1[0] = p[0];
  generate
    for (i=1; i<N; i=i+1) begin: gen_pp1
      assign g1[i] = g[i] | (p[i] & g[i-1]);
      assign p1[i] = p[i] & p[i-1];
    end
  endgenerate

  // 第二级前缀
  assign g2[0] = g1[0];
  assign p2[0] = p1[0];
  assign g2[1] = g1[1];
  assign p2[1] = p1[1];
  generate
    for (i=2; i<N; i=i+1) begin: gen_pp2
      assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
      assign p2[i] = p1[i] & p1[i-2];
    end
  endgenerate

  // 第三级前缀
  assign g3[0] = g2[0];
  assign p3[0] = p2[0];
  assign g3[1] = g2[1];
  assign p3[1] = p2[1];
  assign g3[2] = g2[2];
  assign p3[2] = p2[2];
  assign g3[3] = g2[3];
  assign p3[3] = p2[3];
  generate
    for (i=4; i<N; i=i+1) begin: gen_pp3
      assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
      assign p3[i] = p2[i] & p2[i-4];
    end
  endgenerate

  // 第四级前缀
  assign g4[0] = g3[0];
  assign p4[0] = p3[0];
  assign g4[1] = g3[1];
  assign p4[1] = p3[1];
  assign g4[2] = g3[2];
  assign p4[2] = p3[2];
  assign g4[3] = g3[3];
  assign p4[3] = p3[3];
  assign g4[4] = g3[4];
  assign p4[4] = p3[4];
  assign g4[5] = g3[5];
  assign p4[5] = p3[5];
  assign g4[6] = g3[6];
  assign p4[6] = p3[6];
  assign g4[7] = g3[7];
  assign p4[7] = p3[7];
  generate
    for (i=8; i<N; i=i+1) begin: gen_pp4
      assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
      assign p4[i] = p3[i] & p3[i-8];
    end
  endgenerate

  // 计算进位和掩码
  assign carry = g4;
  assign mask = req ^ carry;

  // 计算前导1的位置
  assign lead_one = req & ~mask;

  // 编码部分保持不变
  integer j;
  always @(*) begin
    index = 0;
    for (j=0; j<N; j=j+1)
      if (lead_one[j]) index = j[$clog2(N)-1:0];
  end

endmodule