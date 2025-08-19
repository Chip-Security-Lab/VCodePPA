//SystemVerilog
module sync_even_parity(
  input wire clk,
  input wire rst,
  input wire valid,         // 发送方数据有效信号
  input wire [15:0] data,   // 输入数据
  output wire ready,        // 接收方准备好信号
  output reg parity         // 计算出的奇偶校验
);
  
  // 始终准备好接收新数据
  assign ready = 1'b1;
  
  // 当valid有效且ready有效时，处理数据
  always @(posedge clk) begin
    if (rst) begin
      parity <= 1'b0;
    end else if (valid && ready) begin
      parity <= ^data;  // 计算偶校验
    end
  end
  
endmodule