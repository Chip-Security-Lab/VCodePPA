//SystemVerilog
module fsm_priority_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr,
  input ready,
  output reg [2:0] intr_id,
  output reg valid
);
  // IEEE 1364-2005 Verilog标准
  
  // 状态定义
  localparam IDLE = 2'b00, 
             DETECT = 2'b01, 
             SERVE = 2'b10, 
             CLEAR = 2'b11;
             
  reg [1:0] state, next_state;
  reg [2:0] next_intr_id;
  reg next_valid;
  reg [7:0] intr_reg;
  
  // 输入寄存器 - 前向重定时，将输入寄存捕获提前
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      intr_reg <= 8'b0;
    else
      intr_reg <= intr;
  end
  
  // 状态转移寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end
  
  // 状态转移逻辑 - 使用寄存的输入
  always @(*) begin
    next_state = state;
    case (state)
      IDLE:   if (|intr_reg) next_state = DETECT;
      DETECT: next_state = SERVE;
      SERVE:  if (ready && valid) next_state = CLEAR;
      CLEAR:  next_state = IDLE;
    endcase
  end
  
  // 组合逻辑部分 - 计算下一个输出值
  always @(*) begin
    next_intr_id = intr_id;
    next_valid = valid;
    
    case (state)
      DETECT: begin
        next_valid = 1'b1;
        casez (intr_reg)
          8'b1???????: next_intr_id = 3'd7;
          8'b01??????: next_intr_id = 3'd6;
          8'b001?????: next_intr_id = 3'd5;
          8'b0001????: next_intr_id = 3'd4;
          8'b00001???: next_intr_id = 3'd3;
          8'b000001??: next_intr_id = 3'd2;
          8'b0000001?: next_intr_id = 3'd1;
          8'b00000001: next_intr_id = 3'd0;
          default:     next_intr_id = 3'd0;
        endcase
      end
      CLEAR: begin
        next_valid = 1'b0;
      end
    endcase
  end
  
  // 输出寄存器 - 更新输出
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'b0;
      valid <= 1'b0;
    end else begin
      intr_id <= next_intr_id;
      valid <= next_valid;
    end
  end
endmodule