//SystemVerilog
//IEEE 1364-2005
module prio_enc_lut #(parameter DEPTH=8)(
  input [DEPTH-1:0] in,
  output reg [$clog2(DEPTH)-1:0] out
);

  // 内部信号定义
  reg [DEPTH-1:0] in_masked;
  integer i;

  always @(*) begin
    // 默认输出
    out = {$clog2(DEPTH){1'b0}};
    
    if (DEPTH == 8) begin
      // 针对DEPTH=8的优化实现
      // 使用并行编码方式而非casez语句，减少层级延迟
      out[2] = |in[7:4];
      out[1] = |in[7:6] || |in[3:2] && ~|in[7:4];
      out[0] = in[7] || in[5] && ~in[7:6] || in[3] && ~|in[7:4] || in[1] && ~|in[7:2];
    end
    else begin
      // 通用方法 - 使用优化的算法
      in_masked = in;
      for(i=0; i<$clog2(DEPTH); i=i+1) begin
        out[i] = |(in_masked & ({DEPTH{1'b1}} << (1<<i)));
        in_masked = in_masked & ~({DEPTH{1'b1}} << (1<<i) & {DEPTH{out[i]}});
      end
    end
  end
endmodule