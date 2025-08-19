//SystemVerilog
module fsm_priority_intr_ctrl(
  input wire clk, rst_n,
  input wire [7:0] intr,
  input wire ack,  // 应答信号(之前的ready)
  output reg [2:0] intr_id,
  output reg req   // 请求信号(之前的intr_active)
);
  // 状态编码优化：使用独热编码以改善时序和功耗
  localparam IDLE   = 4'b0001;
  localparam DETECT = 4'b0010;
  localparam SERVE  = 4'b0100;
  localparam CLEAR  = 4'b1000;
  
  reg [3:0] state, next_state;
  
  // 状态寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end
  
  // 状态转换逻辑，使用并行case语句改善时序
  always @(*) begin
    next_state = state; // 默认保持当前状态
    
    case (1'b1) // 独热编码的case语句
      state[0]: begin // IDLE
        if (|intr) 
          next_state = DETECT;
      end
      
      state[1]: begin // DETECT
        next_state = SERVE;
      end
      
      state[2]: begin // SERVE
        if (ack) 
          next_state = CLEAR;
      end
      
      state[3]: begin // CLEAR
        next_state = IDLE;
      end
      
      default: next_state = IDLE; // 安全状态
    endcase
  end
  
  // 优化中断ID编码和请求信号处理
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'b0;
      req <= 1'b0;
    end
    else begin
      case (1'b1) // 独热编码的case语句
        state[1]: begin // DETECT状态
          req <= 1'b1;
          
          // 使用并行编码器结构优化优先级逻辑
          casez (intr)
            8'b1???????: intr_id <= 3'd7;
            8'b01??????: intr_id <= 3'd6;
            8'b001?????: intr_id <= 3'd5;
            8'b0001????: intr_id <= 3'd4;
            8'b00001???: intr_id <= 3'd3;
            8'b000001??: intr_id <= 3'd2;
            8'b0000001?: intr_id <= 3'd1;
            8'b00000001: intr_id <= 3'd0;
            default:     intr_id <= 3'd0;
          endcase
        end
        
        state[3]: begin // CLEAR状态
          req <= 1'b0;
        end
      endcase
    end
  end
endmodule