//SystemVerilog
module sync_even_parity(
  input clk, rst,
  input [15:0] data,
  input valid,       // 输入数据有效信号
  output reg ready,  // 输出准备好接收信号
  output reg parity, // 偶校验结果
  output reg valid_out // 输出数据有效信号
);

  // 内部状态
  reg calc_done;
  reg [15:0] data_reg;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ready <= 1'b1;      // 复位时准备好接收新数据
      parity <= 1'b0;     // 复位校验位
      valid_out <= 1'b0;  // 复位输出有效信号
      calc_done <= 1'b0;  // 复位计算完成标志
      data_reg <= 16'b0;  // 复位数据寄存器
    end
    else begin
      // 握手逻辑
      if (valid && ready) begin
        // 捕获数据并开始计算
        data_reg <= data;
        parity <= ^data;  // 计算偶校验
        calc_done <= 1'b1;
        ready <= 1'b0;    // 不再接收新数据
        valid_out <= 1'b1; // 表示结果即将有效
      end
      else if (calc_done) begin
        // 计算完成，恢复ready状态
        calc_done <= 1'b0;
        ready <= 1'b1;    // 准备接收下一个数据
        valid_out <= 1'b0; // 结果处理完毕
      end
    end
  end
endmodule