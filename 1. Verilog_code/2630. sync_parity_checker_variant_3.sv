//SystemVerilog
module sync_parity_checker(
  input clk, rst,
  input [7:0] data,
  input parity_in,
  output reg error,
  output reg [3:0] error_count
);
  // 合并了第1阶段和第2阶段 - 同时计算全部8位数据的奇偶校验
  reg parity_complete_stage1;
  reg parity_in_stage1;
  
  // 合并了第3阶段和第4阶段 - 直接检测错误
  reg error_detected;
  
  // 第1阶段: 直接计算全部8位的奇偶校验
  always @(posedge clk) begin
    if (rst) begin
      parity_complete_stage1 <= 1'b0;
      parity_in_stage1 <= 1'b0;
    end else begin
      parity_complete_stage1 <= ^data; // 直接计算全部8位的奇偶性
      parity_in_stage1 <= parity_in;
    end
  end
  
  // 第2阶段: 错误检测
  always @(posedge clk) begin
    if (rst) begin
      error_detected <= 1'b0;
    end else begin
      error_detected <= parity_complete_stage1 ^ parity_in_stage1;
    end
  end
  
  // 第3阶段: 输出寄存器
  always @(posedge clk) begin
    if (rst) begin
      error <= 1'b0;
      error_count <= 4'd0;
    end else begin
      error <= error_detected;
      if (error_detected)
        error_count <= error_count + 1'b1;
    end
  end
endmodule