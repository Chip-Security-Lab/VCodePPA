//SystemVerilog
module reset_startup_delay (
  input wire clk,
  input wire reset_n,
  output reg system_ready
);
  reg [7:0] delay_counter;
  reg [7:0] delay_counter_buf1;
  reg [7:0] delay_counter_buf2;
  reg counter_max_flag;
  
  // 主计数器逻辑
  always @(posedge clk) begin
    if (!reset_n)
      delay_counter <= 8'h00;
    else if (delay_counter < 8'hFF)
      delay_counter <= delay_counter + 1'b1;
  end
  
  // 缓冲寄存器1 - 用于第一级扇出负载分散
  always @(posedge clk) begin
    if (!reset_n)
      delay_counter_buf1 <= 8'h00;
    else
      delay_counter_buf1 <= delay_counter;
  end
  
  // 缓冲寄存器2 - 进一步分散高扇出负载
  always @(posedge clk) begin
    if (!reset_n)
      delay_counter_buf2 <= 8'h00;
    else
      delay_counter_buf2 <= delay_counter_buf1;
  end
  
  // 计数器最大值检测逻辑
  always @(posedge clk) begin
    if (!reset_n)
      counter_max_flag <= 1'b0;
    else
      counter_max_flag <= (delay_counter_buf2 == 8'hFF);
  end
  
  // 系统就绪信号生成
  always @(posedge clk) begin
    if (!reset_n)
      system_ready <= 1'b0;
    else
      system_ready <= counter_max_flag;
  end
  
endmodule