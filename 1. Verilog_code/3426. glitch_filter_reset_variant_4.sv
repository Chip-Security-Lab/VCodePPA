//SystemVerilog
module glitch_filter_reset #(
  parameter GLITCH_CYCLES = 3
) (
  input  wire clk,
  input  wire noisy_rst,
  output wire clean_rst
);
  // 输入缓冲和有效信号控制
  reg noisy_rst_stage1;
  reg valid_stage1;
  
  // 状态和计数器接口信号
  wire [1:0] state;
  wire [$clog2(GLITCH_CYCLES)-1:0] counter;
  
  // 输入流水线阶段
  always @(posedge clk) begin
    noisy_rst_stage1 <= noisy_rst;
    valid_stage1 <= 1'b1; // 一旦复位后，流水线持续有效
  end
  
  // 调用流水线化的状态转换模块
  glitch_filter_state_machine #(
    .GLITCH_CYCLES(GLITCH_CYCLES)
  ) state_machine_inst (
    .clk(clk),
    .input_signal(noisy_rst_stage1),
    .valid_in(valid_stage1),
    .state(state),
    .counter(counter),
    .output_signal(clean_rst)
  );
endmodule

// 流水线化的毛刺滤波状态机模块
module glitch_filter_state_machine #(
  parameter GLITCH_CYCLES = 3
) (
  input  wire clk,
  input  wire input_signal,
  input  wire valid_in,
  output reg [1:0] state,
  output reg [$clog2(GLITCH_CYCLES)-1:0] counter,
  output reg output_signal
);
  // 状态定义
  localparam IDLE_LOW  = 2'b00;
  localparam COUNT_UP  = 2'b01;
  localparam IDLE_HIGH = 2'b10;
  localparam COUNT_DN  = 2'b11;
  
  // 流水线寄存器
  reg input_signal_stage2;
  reg valid_stage2;
  reg [1:0] state_next;
  reg [$clog2(GLITCH_CYCLES)-1:0] counter_next;
  reg output_signal_next;
  
  // 阶段1: 计算下一状态和计数器值
  always @(*) begin
    // 默认保持当前值
    state_next = state;
    counter_next = counter;
    output_signal_next = output_signal;
    
    if (valid_in) begin
      case (state)
        IDLE_LOW: begin
          if (input_signal) begin 
            counter_next = 0; 
            state_next = COUNT_UP; 
          end
        end
        
        COUNT_UP: begin
          if (!input_signal) begin
            state_next = IDLE_LOW;
          end else if (counter == GLITCH_CYCLES-1) begin
            output_signal_next = 1'b1; 
            state_next = IDLE_HIGH;
          end else begin
            counter_next = counter + 1;
          end
        end
        
        IDLE_HIGH: begin
          if (!input_signal) begin 
            counter_next = 0; 
            state_next = COUNT_DN; 
          end
        end
        
        COUNT_DN: begin
          if (input_signal) begin
            state_next = IDLE_HIGH;
          end else if (counter == GLITCH_CYCLES-1) begin
            output_signal_next = 1'b0; 
            state_next = IDLE_LOW;
          end else begin
            counter_next = counter + 1;
          end
        end
      endcase
    end
  end
  
  // 阶段2: 寄存器更新
  always @(posedge clk) begin
    // 流水线寄存器更新
    input_signal_stage2 <= input_signal;
    valid_stage2 <= valid_in;
    
    // 更新状态寄存器
    if (valid_stage2) begin
      state <= state_next;
      counter <= counter_next;
      output_signal <= output_signal_next;
    end
  end
  
  // 初始化状态
  initial begin
    state = IDLE_LOW;
    counter = 0;
    output_signal = 1'b0;
    valid_stage2 = 1'b0;
  end
endmodule