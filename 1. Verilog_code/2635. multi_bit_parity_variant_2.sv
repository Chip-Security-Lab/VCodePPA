//SystemVerilog
module multi_bit_parity(
  input clk,
  input rst_n,
  input req,           // 请求信号，由发送方发出
  input [15:0] data_word,
  output reg ack,      // 应答信号，由接收方发出
  output reg [1:0] parity_bits
);

  // 状态信号
  reg busy;

  // 子模块实例化
  wire [1:0] parity_temp;

  // 奇偶校验计算子模块
  parity_calculator u_parity_calculator (
    .data_word(data_word),
    .parity_bits(parity_temp)
  );

  // 请求-应答握手逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack <= 1'b0;
      parity_bits <= 2'b00;
      busy <= 1'b0;
    end else begin
      if (req && !busy) begin
        busy <= 1'b1;
        ack <= 1'b1;  // 立即应答
      end else if (busy && req) begin
        // 保持应答直到请求撤销
        parity_bits <= parity_temp;
        ack <= 1'b1;
      end else if (busy && !req) begin
        // 请求撤销，握手完成
        busy <= 1'b0;
        ack <= 1'b0;
      end else begin
        ack <= 1'b0;
      end
    end
  end

endmodule

// 奇偶校验计算子模块
module parity_calculator(
  input [15:0] data_word,
  output reg [1:0] parity_bits
);

  always @(*) begin
    parity_bits[0] = ^data_word[7:0];  // 计算低8位的奇偶校验
    parity_bits[1] = ^data_word[15:8]; // 计算高8位的奇偶校验
  end

endmodule