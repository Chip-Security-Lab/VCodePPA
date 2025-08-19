//SystemVerilog
// IEEE 1364-2005 Verilog标准
module prio_enc_gray_error #(parameter N=8)(
  input [N-1:0] req,
  output [$clog2(N)-1:0] gray_out,
  output error
);
  reg [$clog2(N)-1:0] bin_temp;
  wire [$clog2(N)-1:0] bin_out;
  wire any_req;
  integer i;
  
  // 使用显式多路复用器结构实现优先编码
  always @(*) begin
    bin_temp = {$clog2(N){1'b0}};
    for(i=0; i<N; i=i+1) begin
      bin_temp = req[i] ? i[$clog2(N)-1:0] : bin_temp;
    end
  end
  
  // 使用明确的多路复用器替代三元运算符
  assign any_req = |req;
  assign bin_out = any_req ? bin_temp : {$clog2(N){1'b0}};
  
  // 计算格雷码输出
  assign gray_out = (bin_out >> 1) ^ bin_out;
  
  // 错误信号 - 当没有请求时激活
  assign error = ~any_req;
endmodule