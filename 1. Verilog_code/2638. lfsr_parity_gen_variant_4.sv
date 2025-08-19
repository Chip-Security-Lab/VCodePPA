//SystemVerilog
module lfsr_parity_gen(
  input clk, rst,
  input valid,
  output reg ready,
  input [7:0] data_in,
  output reg parity
);
  reg [3:0] lfsr;
  // 为lfsr添加缓冲寄存器
  reg [3:0] lfsr_buf1, lfsr_buf2;
  
  reg [7:0] data_buf;
  reg processing;
  // 添加b0信号和缓冲
  wire b0 = lfsr[3] ^ lfsr[2];
  reg b0_buf1, b0_buf2;
  
  always @(posedge clk) begin
    if (rst) begin
      lfsr <= 4'b1111;
      lfsr_buf1 <= 4'b1111;
      lfsr_buf2 <= 4'b1111;
      b0_buf1 <= 1'b0;
      b0_buf2 <= 1'b0;
      parity <= 1'b0;
      ready <= 1'b1;
      processing <= 1'b0;
      data_buf <= 8'b0;
    end else begin
      // 更新lfsr缓冲
      lfsr_buf1 <= lfsr;
      lfsr_buf2 <= lfsr_buf1;
      
      // 更新b0缓冲
      b0_buf1 <= b0;
      b0_buf2 <= b0_buf1;
      
      if (valid && ready) begin
        data_buf <= data_in;
        processing <= 1'b1;
        ready <= 1'b0;
      end
      
      if (processing) begin
        // 使用b0缓冲更新lfsr
        lfsr <= {lfsr[2:0], b0_buf1};
        // 使用lfsr缓冲计算奇偶校验
        parity <= (^data_buf) ^ lfsr_buf1[0];
        processing <= 1'b0;
        ready <= 1'b1;
      end
    end
  end
endmodule