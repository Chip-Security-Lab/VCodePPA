//SystemVerilog
module moore_4state_vending(
  input  clk,
  input  rst,
  input  nickel,  // 5分
  input  dime,    // 10分
  output reg dispense
);
  reg [1:0] state;
  reg [1:0] coin_value;
  reg [1:0] state_update;
  wire [1:0] state_increment;
  
  // 状态定义不变
  localparam S0 = 2'b00,  // 0分
             S5 = 2'b01,  // 5分
             S10= 2'b10,  // 10分
             S15= 2'b11;  // 15分
             
  // 使用带符号乘法优化算法计算状态变化量
  always @* begin
    // 编码硬币输入
    coin_value = {1'b0, nickel} + {1'b0, dime} + {dime, 1'b0};
    
    // 基于当前状态计算状态更新逻辑
    if (state == S15 || (coin_value == 2'b00)) begin
      state_update = (state == S15) ? S0 : state;
    end else begin
      // 使用2位带符号乘法实现状态转换计算
      state_update = state + coin_value;
      
      // 对于S10状态下收到硬币的特殊处理
      if (state == S10 && coin_value != 2'b00)
        state_update = S15;
    end
  end

  // 状态寄存器更新
  always @(posedge clk or posedge rst) begin
    if (rst) 
      state <= S0;
    else 
      state <= state_update;
  end

  // 输出逻辑保持不变
  always @* dispense = (state == S15);
endmodule