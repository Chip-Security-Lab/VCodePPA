//SystemVerilog
`timescale 1ns / 1ps
module can_error_detector(
  input wire clk, rst_n,
  input wire can_rx, bit_sample_point,
  input wire tx_mode,
  output reg bit_error, stuff_error, form_error, crc_error,
  output reg [7:0] error_count
);
  reg [2:0] consecutive_bits;
  reg expected_bit, received_bit;
  reg [14:0] crc_calc, crc_received;
  
  // IEEE 1364-2005 Verilog标准
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 高效并行复位
      bit_error <= 1'b0;
      stuff_error <= 1'b0;
      form_error <= 1'b0;
      crc_error <= 1'b0;
      error_count <= 8'b0;
      consecutive_bits <= 3'b0;
    end else if (bit_sample_point) begin
      // 优化位错误检测 - 使用单一条件判断
      bit_error <= tx_mode & (can_rx != expected_bit);
      
      // 优化错误计数 - 使用位宽匹配的加法
      error_count <= error_count + ((tx_mode & (can_rx != expected_bit)) ? 8'd1 : 8'd0);
      
      // 优化连续位计数逻辑 - 使用范围比较
      if (can_rx == received_bit) begin
        if (consecutive_bits < 3'b111)
          consecutive_bits <= consecutive_bits + 3'b001;
      end else begin
        consecutive_bits <= 3'b0;
      end
      
      // 优化填充错误检测 - 使用精确阈值比较
      stuff_error <= (consecutive_bits == 3'b100) & (can_rx == received_bit);
    end
  end
endmodule