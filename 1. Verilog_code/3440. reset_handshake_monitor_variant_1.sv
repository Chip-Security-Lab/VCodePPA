//SystemVerilog
module reset_handshake_monitor (
  input  wire clk,
  input  wire reset_req,
  input  wire reset_ack,
  output reg  reset_active,
  output reg  timeout_error
);
  // 状态定义
  localparam IDLE     = 2'b00;
  localparam ACTIVE   = 2'b01;
  localparam COMPLETE = 2'b10;
  
  reg [1:0] state, next_state;
  reg [7:0] timeout_counter;
  
  // 前级寄存器优化
  reg reset_req_r;
  reg reset_ack_r;
  
  // 输入信号缓存
  always @(posedge clk) begin
    reset_req_r <= reset_req;
    reset_ack_r <= reset_ack;
  end
  
  // 状态转换逻辑
  always @(posedge clk) begin
    state <= next_state;
  end
  
  // 组合逻辑状态转换
  always @(*) begin
    next_state = state;
    
    case (state)
      IDLE: 
        if (reset_req_r)
          next_state = ACTIVE;
          
      ACTIVE:
        if (reset_ack_r)
          next_state = COMPLETE;
          
      COMPLETE:
        if (!reset_req_r)
          next_state = IDLE;
          
      default:
        next_state = IDLE;
    endcase
  end
  
  // 输出逻辑和超时计数
  always @(posedge clk) begin
    case (state)
      IDLE: begin
        reset_active <= 1'b0;
        timeout_error <= 1'b0;
        timeout_counter <= 8'd0;
      end
      
      ACTIVE: begin
        reset_active <= 1'b1;
        
        if (!reset_ack_r) begin
          if (timeout_counter != 8'hFF) begin
            timeout_counter <= timeout_counter + 8'd1;
            timeout_error <= 1'b0;
          end else begin
            timeout_error <= 1'b1;
          end
        end
      end
      
      COMPLETE: begin
        reset_active <= 1'b1;
        // 保持超时计数和错误状态
      end
      
      default: begin
        reset_active <= 1'b0;
        timeout_error <= 1'b0;
        timeout_counter <= 8'd0;
      end
    endcase
  end
endmodule