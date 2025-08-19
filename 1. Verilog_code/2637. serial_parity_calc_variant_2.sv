//SystemVerilog
module serial_parity_calc(
  input clk, rst, bit_in, start,
  output reg parity_done,
  output reg parity_bit
);
  reg [2:0] bit_count; // 只需要3位来计数到8
  reg count_en;
  
  // 使用独立的状态管理
  always @(posedge clk) begin
    if (rst || start) begin
      count_en <= 1'b1;
      bit_count <= 3'd0;
      parity_done <= 1'b0;
    end else if (count_en) begin
      if (bit_count == 3'd7) begin
        count_en <= 1'b0;
        parity_done <= 1'b1;
      end
      bit_count <= bit_count + 1'b1;
    end
  end
  
  // 分离奇偶计算逻辑
  always @(posedge clk) begin
    if (rst || start) begin
      parity_bit <= 1'b0;
    end else if (count_en) begin
      parity_bit <= parity_bit ^ bit_in;
    end
  end
endmodule