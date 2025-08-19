//SystemVerilog
module moore_4state_vending(
  input  clk,
  input  rst,
  input  nickel,  // 5分
  input  dime,    // 10分
  output dispense
);
  reg [1:0] state, next_state;
  
  // 使用参数而非局部参数以便综合工具更好地优化
  parameter S0 = 2'b00, // 0分
            S5 = 2'b01, // 5分
            S10= 2'b10, // 10分
            S15= 2'b11; // 15分

  // 复位逻辑优化为异步复位，减少时钟周期延迟
  always_ff @(posedge clk or posedge rst) begin
    if (rst) 
      state <= S0;
    else 
      state <= next_state;
  end

  // 优化状态转换逻辑，使用编码优化的状态转移表达式
  always_comb begin
    // 默认值设置
    next_state = state;
    
    case (state)
      S0: begin
        // 优先处理dime输入，减少比较链路径
        if (nickel & ~dime)
          next_state = S5;
        else if (dime)
          next_state = S10;
      end
      
      S5: begin
        // 优先处理到达S15的路径
        if (dime)
          next_state = S15;
        else if (nickel)
          next_state = S10;
      end
      
      S10: begin
        // 简化条件，避免冗余比较
        if (nickel | dime)
          next_state = S15;
      end
      
      S15: begin
        // 无条件转移
        next_state = S0;
      end
      
      default: next_state = S0; // 防止未定义状态
    endcase
  end

  // 使用状态比特定位检测，减少复杂性并提高效率
  assign dispense = state[1] & state[0]; // 等同于state == S15(2'b11)
  
endmodule