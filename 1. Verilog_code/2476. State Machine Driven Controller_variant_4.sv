//SystemVerilog
//IEEE 1364-2005
module fsm_priority_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr,
  input ack,
  output reg [2:0] intr_id,
  output reg intr_active
);
  // 状态定义
  localparam IDLE = 2'b00, 
             DETECT = 2'b01, 
             SERVE = 2'b10, 
             CLEAR = 2'b11;
             
  // 状态寄存器
  reg [1:0] state, next_state;
  
  // 组合逻辑输出信号
  wire [2:0] next_intr_id;
  wire next_intr_active;
  
  // 组合逻辑模块实例化
  fsm_comb_logic fsm_comb_inst (
    .state(state),
    .intr(intr),
    .ack(ack),
    .next_state(next_state),
    .next_intr_id(next_intr_id),
    .next_intr_active(next_intr_active)
  );
  
  // 时序逻辑块
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      intr_id <= 3'b0;
      intr_active <= 1'b0;
    end else begin
      state <= next_state;
      intr_id <= next_intr_id;
      intr_active <= next_intr_active;
    end
  end
endmodule

// 组合逻辑独立模块
module fsm_comb_logic(
  input [1:0] state,
  input [7:0] intr,
  input ack,
  output reg [1:0] next_state,
  output reg [2:0] next_intr_id,
  output reg next_intr_active
);
  // 状态定义
  localparam IDLE = 2'b00, 
             DETECT = 2'b01, 
             SERVE = 2'b10, 
             CLEAR = 2'b11;
  
  // 组合逻辑 - 状态转换
  always @(*) begin
    next_state = state;
    
    case (state)
      IDLE: begin
        if (|intr) begin
          next_state = DETECT;
        end else begin
          next_state = IDLE;
        end
      end
      
      DETECT: begin
        next_state = SERVE;
      end
      
      SERVE: begin
        if (ack) begin
          next_state = CLEAR;
        end else begin
          next_state = SERVE;
        end
      end
      
      CLEAR: begin
        next_state = IDLE;
      end
      
      default: begin
        next_state = IDLE;
      end
    endcase
  end
  
  // 组合逻辑 - 中断处理逻辑
  always @(*) begin
    // 默认保持当前值
    next_intr_id = 3'd0;
    next_intr_active = 1'b0;
    
    case (state)
      IDLE: begin
        next_intr_active = 1'b0;
        next_intr_id = 3'd0;
      end
      
      DETECT: begin
        next_intr_active = 1'b1;
        
        if (intr[7]) begin
          next_intr_id = 3'd7;
        end else if (intr[6]) begin
          next_intr_id = 3'd6;
        end else if (intr[5]) begin
          next_intr_id = 3'd5;
        end else if (intr[4]) begin
          next_intr_id = 3'd4;
        end else if (intr[3]) begin
          next_intr_id = 3'd3;
        end else if (intr[2]) begin
          next_intr_id = 3'd2;
        end else if (intr[1]) begin
          next_intr_id = 3'd1;
        end else if (intr[0]) begin
          next_intr_id = 3'd0;
        end else begin
          next_intr_id = 3'd0;
        end
      end
      
      SERVE: begin
        next_intr_active = 1'b1;
        next_intr_id = 3'd0;
      end
      
      CLEAR: begin
        next_intr_active = 1'b0;
        next_intr_id = 3'd0;
      end
      
      default: begin
        next_intr_active = 1'b0;
        next_intr_id = 3'd0;
      end
    endcase
  end
endmodule