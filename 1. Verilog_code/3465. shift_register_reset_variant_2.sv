//SystemVerilog
//IEEE 1364-2005
module shift_register_reset #(
  parameter WIDTH = 16
)(
  input wire clk,       // 时钟信号
  input wire reset,     // 复位信号
  input wire shift_en,  // 移位使能
  input wire data_in,   // 输入数据
  output reg [WIDTH-1:0] shift_data  // 移位数据输出
);

  // 使用局部参数来提高可读性
  localparam RESET_VALUE = {WIDTH{1'b0}};
  
  // 查找表实现
  reg [WIDTH-1:0] lut_next_state[0:3];
  reg [1:0] control_signals;
  
  // 为高扇出信号添加缓冲寄存器
  reg [WIDTH-1:0] lut_next_state_buf1;
  reg [WIDTH-1:0] lut_next_state_buf2;
  
  // 组合控制信号
  always @(*) begin
    control_signals = {reset, shift_en};
  end
  
  // 预计算下一状态查找表
  always @(*) begin
    // 复位状态
    lut_next_state[2'b10] = RESET_VALUE;
    lut_next_state[2'b11] = RESET_VALUE;
    
    // 移位状态
    lut_next_state[2'b01] = {shift_data[WIDTH-2:0], data_in};
    
    // 保持状态
    lut_next_state[2'b00] = shift_data;
  end
  
  // 时序逻辑 - 添加缓冲寄存器分散负载
  always @(posedge clk) begin
    // 第一级缓冲
    lut_next_state_buf1 <= lut_next_state[control_signals];
    lut_next_state_buf2 <= lut_next_state[control_signals];
    
    // 使用缓冲后的信号更新输出
    if (WIDTH <= 8) begin
      // 对于较小的位宽，使用第一个缓冲寄存器
      shift_data <= lut_next_state_buf1;
    end else begin
      // 对于较大的位宽，使用第二个缓冲寄存器以平衡负载
      shift_data <= lut_next_state_buf2;
    end
  end

endmodule