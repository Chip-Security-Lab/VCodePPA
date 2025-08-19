//SystemVerilog
module tdm_parity_gen(
  input clk, rst_n,
  input [7:0] stream_a, stream_b,
  input stream_sel,
  input valid_in,   // 数据有效信号 (类似原req信号)
  output ready_out, // 准备接收信号 (类似原ack信号)
  output reg parity_out,
  output reg valid_out  // 输出数据有效信号
);
  reg [7:0] selected_stream;
  reg data_processed;
  
  // 当模块准备接收新数据时，ready信号置高
  assign ready_out = !data_processed || valid_out;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      selected_stream <= 8'h0;
      parity_out <= 1'b0;
      data_processed <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      if (valid_in && ready_out) begin
        // 有效握手发生时，接收并处理数据
        selected_stream <= stream_sel ? stream_b : stream_a;
        data_processed <= 1'b1;
        valid_out <= 1'b0; // 重置输出有效信号，等待处理完成
      end
      
      if (data_processed && !valid_out) begin
        // 当数据已处理但输出尚未有效时，计算奇偶校验并输出
        parity_out <= ^selected_stream;
        valid_out <= 1'b1;
      end
      
      if (valid_out) begin
        // 当输出有效信号已置高，重置处理状态以接收新数据
        data_processed <= 1'b0;
      end
    end
  end
endmodule