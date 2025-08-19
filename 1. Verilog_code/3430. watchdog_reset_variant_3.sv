//SystemVerilog
module watchdog_reset #(
  parameter TIMEOUT = 1024
) (
  input  wire clk,           // 系统时钟
  input  wire watchdog_kick, // 喂狗信号
  input  wire rst_n,         // 低电平有效复位
  output wire watchdog_rst   // 看门狗复位输出
);
  
  // 定义状态信号和寄存器
  localparam COUNT_WIDTH = $clog2(TIMEOUT);
  
  reg [COUNT_WIDTH-1:0] counter_r;      // 计数器寄存器
  reg watchdog_rst_r;                   // 复位输出寄存器
  
  // 使用单一组合逻辑块优化计数和复位逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_r <= {COUNT_WIDTH{1'b0}};
      watchdog_rst_r <= 1'b0;
    end else begin
      if (watchdog_kick) begin
        // 喂狗时重置计数器和复位信号
        counter_r <= {COUNT_WIDTH{1'b0}};
        watchdog_rst_r <= 1'b0;
      end else begin
        // 优化比较链，使用范围比较
        if (counter_r < TIMEOUT-1) begin
          counter_r <= counter_r + 1'b1;
          watchdog_rst_r <= 1'b0;
        end else begin
          // 达到超时阈值，触发复位
          counter_r <= counter_r;
          watchdog_rst_r <= 1'b1;
        end
      end
    end
  end
  
  // 输出直接连接到寄存器，减少中间信号
  assign watchdog_rst = watchdog_rst_r;

endmodule