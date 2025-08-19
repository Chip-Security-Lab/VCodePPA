//SystemVerilog
// 顶层模块
module glitch_filter_reset #(
  parameter GLITCH_CYCLES = 3
) (
  input  wire clk,
  input  wire noisy_rst,
  output wire clean_rst
);
  
  // 内部信号定义
  wire [1:0] state_out;
  wire [1:0] next_state;
  wire [$clog2(GLITCH_CYCLES)-1:0] counter_out;
  wire [$clog2(GLITCH_CYCLES)-1:0] next_counter;
  wire next_clean_rst;
  
  // FSM控制器子模块实例化
  fsm_controller #(
    .GLITCH_CYCLES(GLITCH_CYCLES)
  ) fsm_ctrl_inst (
    .state(state_out),
    .counter(counter_out),
    .clean_rst_in(clean_rst),
    .noisy_rst(noisy_rst),
    .next_state(next_state),
    .next_counter(next_counter),
    .next_clean_rst(next_clean_rst)
  );
  
  // 状态寄存器子模块实例化
  state_registers #(
    .GLITCH_CYCLES(GLITCH_CYCLES)
  ) state_reg_inst (
    .clk(clk),
    .next_state(next_state),
    .next_counter(next_counter),
    .next_clean_rst(next_clean_rst),
    .state(state_out),
    .counter(counter_out),
    .clean_rst(clean_rst)
  );
  
endmodule

// FSM控制器子模块 - 负责状态转移逻辑
module fsm_controller #(
  parameter GLITCH_CYCLES = 3
) (
  input  wire [1:0] state,
  input  wire [$clog2(GLITCH_CYCLES)-1:0] counter,
  input  wire clean_rst_in,
  input  wire noisy_rst,
  output reg  [1:0] next_state,
  output reg  [$clog2(GLITCH_CYCLES)-1:0] next_counter,
  output reg  next_clean_rst
);
  
  // 状态定义
  localparam IDLE = 2'b00;
  localparam COUNT_TO_ASSERT = 2'b01;
  localparam ASSERTED = 2'b10;
  localparam COUNT_TO_DEASSERT = 2'b11;
  
  // 状态转移逻辑
  always @(*) begin
    next_state = state;
    next_counter = counter;
    next_clean_rst = clean_rst_in;
    
    case (state)
      IDLE: 
        if (noisy_rst) begin
          next_counter = '0;
          next_state = COUNT_TO_ASSERT;
        end
      
      COUNT_TO_ASSERT: 
        if (!noisy_rst) begin
          next_state = IDLE;
        end
        else if (counter == GLITCH_CYCLES-1) begin
          next_clean_rst = 1'b1;
          next_state = ASSERTED;
        end
        else begin
          next_counter = counter + 1'b1;
        end
      
      ASSERTED:
        if (!noisy_rst) begin
          next_counter = '0;
          next_state = COUNT_TO_DEASSERT;
        end
      
      COUNT_TO_DEASSERT:
        if (noisy_rst) begin
          next_state = ASSERTED;
        end
        else if (counter == GLITCH_CYCLES-1) begin
          next_clean_rst = 1'b0;
          next_state = IDLE;
        end
        else begin
          next_counter = counter + 1'b1;
        end
    endcase
  end
  
endmodule

// 状态寄存器子模块 - 负责同步寄存器更新
module state_registers #(
  parameter GLITCH_CYCLES = 3
) (
  input  wire clk,
  input  wire [1:0] next_state,
  input  wire [$clog2(GLITCH_CYCLES)-1:0] next_counter,
  input  wire next_clean_rst,
  output reg  [1:0] state,
  output reg  [$clog2(GLITCH_CYCLES)-1:0] counter,
  output reg  clean_rst
);
  
  // 状态更新寄存器
  always @(posedge clk) begin
    state <= next_state;
  end
  
  // 计数器更新寄存器
  always @(posedge clk) begin
    counter <= next_counter;
  end
  
  // 输出寄存器更新
  always @(posedge clk) begin
    clean_rst <= next_clean_rst;
  end
  
endmodule