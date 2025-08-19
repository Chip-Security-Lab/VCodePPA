//SystemVerilog
module power_on_reset #(
  parameter POR_CYCLES = 32
) (
  input wire clk,
  input wire power_good,
  output reg system_rst_n
);
  reg [$clog2(POR_CYCLES)-1:0] por_counter;
  reg [$clog2(POR_CYCLES)-1:0] por_counter_buf1;
  reg [$clog2(POR_CYCLES)-1:0] por_counter_buf2;
  reg por_counter_max_flag;
  
  always @(posedge clk or negedge power_good) begin
    if (!power_good) begin
      por_counter <= 0;
      por_counter_buf1 <= 0;
      por_counter_buf2 <= 0;
      por_counter_max_flag <= 1'b0;
      system_rst_n <= 1'b0;
    end else begin
      // 更新主计数器
      if (por_counter < POR_CYCLES-1) 
        por_counter <= por_counter + 1;
      
      // 缓冲寄存器1 - 用于比较逻辑
      por_counter_buf1 <= por_counter;
      
      // 缓冲寄存器2 - 用于其他可能的逻辑操作
      por_counter_buf2 <= por_counter;
      
      // 使用缓冲的计数器值进行标志计算
      por_counter_max_flag <= (por_counter_buf1 == POR_CYCLES-1);
      
      // 使用标志位设置系统复位
      system_rst_n <= por_counter_max_flag;
    end
  end
endmodule