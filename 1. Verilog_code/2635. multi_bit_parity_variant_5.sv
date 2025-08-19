//SystemVerilog
module multi_bit_parity (
  input clk,
  input rst_n,
  // 输入数据接口 - Valid-Ready握手
  input [15:0] data_word,
  input data_valid,
  output reg data_ready,
  // 输出数据接口 - Valid-Ready握手
  output reg [1:0] parity_bits,
  output reg parity_valid,
  input parity_ready
);

  // 内部信号
  reg [15:0] data_word_reg;
  reg [1:0] parity_calc;
  reg processing;

  // 计算奇偶校验
  always @(*) begin
    parity_calc[0] = ^data_word_reg[7:0];
    parity_calc[1] = ^data_word_reg[15:8];
  end

  // 控制逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_ready <= 1'b1;
      parity_valid <= 1'b0;
      processing <= 1'b0;
      data_word_reg <= 16'b0;
      parity_bits <= 2'b0;
    end else begin
      // 输入握手
      if (data_valid && data_ready) begin
        data_word_reg <= data_word;
        data_ready <= 1'b0;
        processing <= 1'b1;
      end

      // 处理阶段
      if (processing) begin
        parity_bits <= parity_calc;
        parity_valid <= 1'b1;
        processing <= 1'b0;
      end

      // 输出握手
      if (parity_valid && parity_ready) begin
        parity_valid <= 1'b0;
        data_ready <= 1'b1; // 准备接收下一个数据
      end
    end
  end

endmodule