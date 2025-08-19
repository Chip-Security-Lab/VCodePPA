//SystemVerilog
module delayed_reset_release #(
  parameter DELAY_CYCLES = 12
) (
  input  wire clk,
  input  wire reset_in,
  output reg  reset_out
);
  reg [$clog2(DELAY_CYCLES):0] delay_counter;
  reg reset_falling;
  
  always @(posedge clk) begin
    // 简化reset_falling逻辑，使用逻辑AND
    reset_falling <= reset_in && !reset_out;
    
    // 简化reset_out逻辑，使用布尔代数的或运算
    reset_out <= reset_in || (|delay_counter);
    
    // 优化状态机逻辑，减少冗余条件检查
    if (reset_in) begin
      // 重置计数器
      delay_counter <= DELAY_CYCLES;
    end else if (|delay_counter) begin
      // 计数器递减
      delay_counter <= delay_counter - 1'b1;
    end else begin
      // 保持为零
      delay_counter <= '0;
    end
  end
endmodule