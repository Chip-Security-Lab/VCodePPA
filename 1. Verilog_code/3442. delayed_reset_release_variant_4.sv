//SystemVerilog
module delayed_reset_release #(
  parameter DELAY_CYCLES = 12
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  // 声明计数器寄存器
  reg [$clog2(DELAY_CYCLES):0] delay_counter;
  reg reset_falling;
  
  // 定义控制状态信号
  wire [1:0] counter_ctrl = {reset_in, |delay_counter};
  
  always @(posedge clk) begin
    // 检测复位信号下降沿
    reset_falling <= reset_in & ~reset_out;
    // 更新复位输出状态
    reset_out <= reset_in | (delay_counter != 0);
    
    // 使用if-else级联结构替代case语句
    if (reset_in == 1'b1) begin
      // 对应原来的 2'b10, 2'b11 分支
      delay_counter <= DELAY_CYCLES;
    end
    else if (|delay_counter) begin
      // 对应原来的 2'b01 分支: reset_in == 0 且 delay_counter > 0
      delay_counter <= delay_counter - 1'b1;
    end
    else begin
      // 对应原来的 2'b00 分支: reset_in == 0 且 delay_counter == 0
      delay_counter <= delay_counter;
    end
  end
endmodule