//SystemVerilog
module state_machine_reset(
  input wire clk,         // 时钟信号
  input wire rst_n,       // 异步低电平复位
  input wire input_bit,   // 输入位
  output reg valid_sequence // 有效序列输出
);
  // 使用独热编码代替二进制编码以提高效率和可靠性
  localparam [3:0] S0 = 4'b0001, 
                   S1 = 4'b0010, 
                   S2 = 4'b0100, 
                   S3 = 4'b1000;
  
  reg [3:0] state, next_state;
  
  // 状态寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      state <= S0;
    else 
      state <= next_state;
  end
  
  // 组合逻辑 - 状态转换和输出
  always @(*) begin
    // 默认状态保持，避免锁存器生成
    next_state = state;
    
    // 使用if-else结构替代独热编码的case比较
    if (state[0]) begin
      if (input_bit) begin
        next_state = S1;
      end else begin
        next_state = S0;
      end
    end else if (state[1]) begin
      if (input_bit) begin
        next_state = S1;
      end else begin
        next_state = S2;
      end
    end else if (state[2]) begin
      if (input_bit) begin
        next_state = S3;
      end else begin
        next_state = S0;
      end
    end else if (state[3]) begin
      if (input_bit) begin
        next_state = S1;
      end else begin
        next_state = S2;
      end
    end else begin
      next_state = S0; // 安全状态，防止未预期状态
    end
    
    // 输出逻辑
    if (state[3]) begin
      valid_sequence = 1'b1;
    end else begin
      valid_sequence = 1'b0;
    end
  end
endmodule