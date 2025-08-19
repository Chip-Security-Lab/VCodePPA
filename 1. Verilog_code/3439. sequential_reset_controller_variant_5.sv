//SystemVerilog
module sequential_reset_controller (
  input wire clk,
  input wire rst_trigger,
  output reg [3:0] rst_vector
);
  // 状态编码定义
  localparam IDLE = 2'b00, RESET = 2'b01, RELEASE = 2'b10;
  
  reg [1:0] state, next_state;
  reg [2:0] step, next_step;
  reg [3:0] next_rst_vector;
  
  // 状态和步骤寄存器更新
  always @(posedge clk) begin
    state <= next_state;
    step <= next_step;
  end
  
  // 复位向量寄存器更新 - 单独处理输出信号
  always @(posedge clk) begin
    rst_vector <= next_rst_vector;
  end
  
  // 状态转换逻辑 - 专注于FSM状态转换
  always @(*) begin
    // 默认保持当前状态
    next_state = state;
    
    case (state)
      IDLE: begin
        if (rst_trigger)
          next_state = RESET;
      end
      
      RESET: begin
        if (step >= 3'd4)
          next_state = RELEASE;
      end
      
      RELEASE: begin
        if (step >= 3'd4)
          next_state = IDLE;
      end
      
      default: begin
        next_state = IDLE;
      end
    endcase
  end
  
  // 步骤计数器逻辑 - 专注于时序计数控制
  always @(*) begin
    // 默认保持当前步骤
    next_step = step;
    
    case (state)
      IDLE: begin
        if (rst_trigger)
          next_step = 3'd0;
      end
      
      RESET: begin
        if (step < 3'd4)
          next_step = step + 3'd1;
        else
          next_step = 3'd0; // 准备进入RELEASE状态
      end
      
      RELEASE: begin
        if (step < 3'd4)
          next_step = step + 3'd1;
        else
          next_step = 3'd0; // 准备返回IDLE状态
      end
      
      default: begin
        next_step = 3'd0;
      end
    endcase
  end
  
  // 复位向量输出逻辑 - 专注于输出生成
  always @(*) begin
    // 默认保持当前复位向量
    next_rst_vector = rst_vector;
    
    case (state)
      IDLE: begin
        if (rst_trigger)
          next_rst_vector = 4'b1111; // 全部复位
      end
      
      RESET: begin
        // 在RESET状态保持复位向量
      end
      
      RELEASE: begin
        if (step < 3'd4)
          next_rst_vector[step] = 1'b0; // 逐个释放复位信号
      end
      
      default: begin
        next_rst_vector = 4'b0000; // 安全默认值
      end
    endcase
  end
  
endmodule