//SystemVerilog
module glitch_filter_reset #(
  parameter GLITCH_CYCLES = 3
) (
  input wire clk,
  input wire noisy_rst,
  output reg clean_rst
);
  // 状态定义
  localparam IDLE          = 2'b00;
  localparam FILTER_ASSERT = 2'b01;
  localparam ASSERTED      = 2'b10;
  localparam FILTER_DEASSERT = 2'b11;
  
  reg [1:0] state;
  reg [$clog2(GLITCH_CYCLES)-1:0] counter;
  
  // 输入预寄存
  reg noisy_rst_reg;
  
  // 注册输入信号
  always @(posedge clk) begin
    noisy_rst_reg <= noisy_rst;
  end
  
  // 重定时：将输出寄存器向前移动到组合逻辑前
  // 直接在状态机中处理clean_rst信号
  reg clean_rst_pre;  // 预输出寄存器
  
  // 状态寄存器更新
  always @(posedge clk) begin
    state <= next_state;
    counter <= next_counter;
    clean_rst <= clean_rst_pre; // 输出寄存器采样预输出信号
  end
  
  // 组合逻辑和状态计算
  reg [1:0] next_state;
  reg [$clog2(GLITCH_CYCLES)-1:0] next_counter;
  
  // 下一状态逻辑和预输出计算
  always @(*) begin
    next_state = state;
    next_counter = counter;
    clean_rst_pre = clean_rst; // 默认保持当前值
    
    case (state)
      IDLE: begin
        if (noisy_rst_reg) begin
          next_counter = 0;
          next_state = FILTER_ASSERT;
        end
      end
      
      FILTER_ASSERT: begin
        if (!noisy_rst_reg) begin
          next_state = IDLE;
        end
        else if (counter == GLITCH_CYCLES-1) begin
          clean_rst_pre = 1'b1; // 直接在组合逻辑中计算输出
          next_state = ASSERTED;
        end
        else begin
          next_counter = counter + 1;
        end
      end
      
      ASSERTED: begin
        clean_rst_pre = 1'b1; // 确保在ASSERTED状态维持输出
        if (!noisy_rst_reg) begin
          next_counter = 0;
          next_state = FILTER_DEASSERT;
        end
      end
      
      FILTER_DEASSERT: begin
        if (noisy_rst_reg) begin
          next_state = ASSERTED;
        end
        else if (counter == GLITCH_CYCLES-1) begin
          clean_rst_pre = 1'b0; // 直接在组合逻辑中计算输出
          next_state = IDLE;
        end
        else begin
          next_counter = counter + 1;
        end
      end
    endcase
  end
  
endmodule