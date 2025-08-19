//SystemVerilog
module prio_enc_lut #(parameter DEPTH=8)(
  input [DEPTH-1:0] in,
  output reg [$clog2(DEPTH)-1:0] out
);

// 并行前缀减法器实现
wire [DEPTH-1:0] g, p;
wire [DEPTH-1:0] carry;

// 生成和传播信号
genvar i;
generate
  for(i=0; i<DEPTH; i=i+1) begin: gen_pp
    assign g[i] = in[i];
    assign p[i] = ~in[i];
  end
endgenerate

// 并行前缀树
wire [DEPTH-1:0] g_level1, p_level1;
wire [DEPTH-1:0] g_level2, p_level2;
wire [DEPTH-1:0] g_level3, p_level3;

// 第一级
assign g_level1[0] = g[0];
assign p_level1[0] = p[0];
generate
  for(i=1; i<DEPTH; i=i+1) begin: level1
    assign g_level1[i] = g[i] | (p[i] & g_level1[i-1]);
    assign p_level1[i] = p[i] & p_level1[i-1];
  end
endgenerate

// 第二级
assign g_level2[0] = g_level1[0];
assign p_level2[0] = p_level1[0];
generate
  for(i=1; i<DEPTH; i=i+1) begin: level2
    assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-1]);
    assign p_level2[i] = p_level1[i] & p_level1[i-1];
  end
endgenerate

// 第三级
assign g_level3[0] = g_level2[0];
assign p_level3[0] = p_level2[0];
generate
  for(i=1; i<DEPTH; i=i+1) begin: level3
    assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-1]);
    assign p_level3[i] = p_level2[i] & p_level2[i-1];
  end
endgenerate

// 输出编码
always @(*) begin
  out = 0;
  if (DEPTH == 8) begin
    casez(g_level3)
      8'b1???_????: out = 3'd7;
      8'b01??_????: out = 3'd6;
      8'b001?_????: out = 3'd5;
      8'b0001_????: out = 3'd4;
      8'b0000_1???: out = 3'd3;
      8'b0000_01??: out = 3'd2;
      8'b0000_001?: out = 3'd1;
      default: out = 3'd0;
    endcase
  end
  else begin
    integer i;
    for(i=DEPTH-1; i>=0; i=i-1)
      if(g_level3[i]) out = i[$clog2(DEPTH)-1:0];
  end
end

endmodule