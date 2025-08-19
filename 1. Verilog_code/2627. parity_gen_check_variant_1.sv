//SystemVerilog
module parity_gen_check(
  input wire clk,        // 时钟信号
  input wire rst_n,      // 复位信号，低电平有效
  input wire [7:0] tx_data,
  input wire rx_parity,
  output reg tx_parity,
  output reg error_detected
);

  // 内部信号定义
  reg [7:0] tx_data_r;
  reg rx_parity_r;
  wire tx_parity_w;
  
  // 第一级流水线：寄存输入数据
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_r <= 8'h0;
      rx_parity_r <= 1'b0;
    end else begin
      tx_data_r <= tx_data;
      rx_parity_r <= rx_parity;
    end
  end
  
  // 奇偶校验计算逻辑
  assign tx_parity_w = ^tx_data_r;
  
  // 第二级流水线：寄存计算结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_parity <= 1'b0;
      error_detected <= 1'b0;
    end else begin
      tx_parity <= tx_parity_w;
      error_detected <= rx_parity_r ^ tx_parity_w;
    end
  end

endmodule