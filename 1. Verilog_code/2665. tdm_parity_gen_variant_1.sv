//SystemVerilog
module tdm_parity_gen(
  input clk, rst_n,
  input [7:0] stream_a, stream_b,
  input stream_sel,
  output reg parity_out
);
  
  // 计算奇偶校验的组合逻辑
  reg [7:0] selected_stream;
  reg calculated_parity;
  
  // 使用if-else结构替代条件运算符选择流
  always @(*) begin
    if (stream_sel) begin
      selected_stream = stream_b;
    end else begin
      selected_stream = stream_a;
    end
  end
  
  // 使用if-else结构计算奇偶校验
  always @(*) begin
    calculated_parity = ^selected_stream;
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_out <= 1'b0;
    end else begin
      parity_out <= calculated_parity;
    end
  end
endmodule