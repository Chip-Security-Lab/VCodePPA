//SystemVerilog
module watchdog_reset #(parameter TIMEOUT = 1000)(
  input clk, ext_rst_n, watchdog_clear,
  output reg watchdog_rst
);
  localparam TIMER_WIDTH = $clog2(TIMEOUT);
  reg [TIMER_WIDTH-1:0] timer;
  reg timeout_detected;
  reg timer_at_limit_reg;
  
  // 将组合逻辑放在寄存器前面
  wire timer_at_limit = (timer == TIMEOUT-1);
  
  // 寄存预计算的组合逻辑结果
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      timer_at_limit_reg <= 0;
    end else begin
      timer_at_limit_reg <= timer_at_limit;
    end
  end
  
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      timer <= 0;
      timeout_detected <= 0;
      watchdog_rst <= 0;
    end else if (watchdog_clear) begin
      timer <= 0;
      timeout_detected <= 0;
      watchdog_rst <= 0;
    end else begin
      // 使用预计算的寄存器值，减少关键路径延迟
      if (timer_at_limit_reg || timeout_detected) begin
        timeout_detected <= 1;
        watchdog_rst <= 1;
        // 计时器达到限制后保持不变
        timer <= timer;
      end else begin
        // 计时器正常递增
        timer <= timer + 1'b1;
      end
    end
  end
endmodule