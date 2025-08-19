//SystemVerilog
// 顶层模块
module state_machine_reset(
  input wire clk,          // 时钟信号
  input wire rst_n,        // 低电平有效的复位信号
  input wire input_bit,    // 输入位信号
  output wire valid_sequence // 有效序列输出指示
);
  
  // 内部信号定义
  wire [1:0] current_state;
  wire input_bit_synced;
  
  // 输入同步子模块实例化
  input_synchronizer u_input_sync (
    .clk          (clk),
    .rst_n        (rst_n),
    .input_bit    (input_bit),
    .input_synced (input_bit_synced)
  );
  
  // 状态控制器子模块实例化
  state_controller u_state_ctrl (
    .clk           (clk),
    .rst_n         (rst_n),
    .input_bit     (input_bit_synced),
    .current_state (current_state)
  );
  
  // 输出生成器子模块实例化
  output_generator u_output_gen (
    .clk            (clk),
    .rst_n          (rst_n),
    .current_state  (current_state),
    .input_bit      (input_bit_synced),
    .valid_sequence (valid_sequence)
  );
  
endmodule

// 输入同步子模块
module input_synchronizer (
  input  wire clk,          // 时钟信号
  input  wire rst_n,        // 低电平有效的复位信号
  input  wire input_bit,    // 输入位信号
  output reg  input_synced  // 同步后的输入信号
);
  
  // 输入寄存器 - 前向重定时，将寄存器前移到组合逻辑之前
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      input_synced <= 1'b0;
    else 
      input_synced <= input_bit;
  end
  
endmodule

// 状态控制器子模块
module state_controller (
  input  wire       clk,           // 时钟信号
  input  wire       rst_n,         // 低电平有效的复位信号
  input  wire       input_bit,     // 同步后的输入信号
  output reg  [1:0] current_state  // 当前状态
);
  
  // 状态编码定义
  localparam S0 = 2'b00, 
             S1 = 2'b01, 
             S2 = 2'b10, 
             S3 = 2'b11;
  
  // 状态转移逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= S0;
    end else begin
      case (current_state)
        S0: current_state <= input_bit ? S1 : S0;
        S1: current_state <= input_bit ? S1 : S2;
        S2: current_state <= input_bit ? S3 : S0;
        S3: current_state <= input_bit ? S1 : S2;
        default: current_state <= S0;
      endcase
    end
  end
  
endmodule

// 输出生成器子模块
module output_generator (
  input  wire       clk,            // 时钟信号
  input  wire       rst_n,          // 低电平有效的复位信号
  input  wire [1:0] current_state,  // 当前状态
  input  wire       input_bit,      // 同步后的输入信号
  output reg        valid_sequence  // 有效序列输出指示
);
  
  // 状态编码定义
  localparam S2 = 2'b10;
  
  // 输出逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      valid_sequence <= 1'b0;
    else
      valid_sequence <= (current_state == S2 && input_bit);  // 预测性计算输出
  end
  
endmodule