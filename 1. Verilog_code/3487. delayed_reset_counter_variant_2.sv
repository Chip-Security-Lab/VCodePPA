//SystemVerilog
module one_hot_encoder_req_ack(
  input clk, rst,
  input req,          // 请求信号，由发送方发出
  input [2:0] binary_in,
  output reg [7:0] one_hot_out,
  output reg ack      // 应答信号，由接收方发出
);
  
  reg data_processed;
  reg [2:0] binary_in_reg;
  
  always @(posedge clk) begin
    if (rst) begin
      one_hot_out <= 8'h00;
      ack <= 1'b0;
      data_processed <= 1'b0;
      binary_in_reg <= 3'b000;
    end
    else begin
      if (req && !data_processed) begin
        // 捕获输入数据
        binary_in_reg <= binary_in;
        // 进行一热编码转换
        one_hot_out <= (8'h01 << binary_in);
        // 设置应答信号
        ack <= 1'b1;
        data_processed <= 1'b1;
      end
      else if (!req) begin
        // 请求信号撤销后，复位应答信号和处理状态
        ack <= 1'b0;
        data_processed <= 1'b0;
      end
    end
  end
endmodule