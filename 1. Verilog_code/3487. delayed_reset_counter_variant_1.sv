//SystemVerilog
module one_hot_encoder_req_ack(
  input clk, rst,
  input [2:0] binary_in,
  input req,              // 输入请求信号，替代原来的valid信号
  output reg ack,         // 输出应答信号，替代原来的ready信号
  output reg [7:0] one_hot_out
);
  
  // 状态定义
  localparam IDLE = 1'b0;
  localparam BUSY = 1'b1;
  
  // 内部状态寄存器
  reg state, next_state;
  
  // 状态转换逻辑
  always @(posedge clk or posedge rst) begin
    if (rst)
      state <= IDLE;
    else
      state <= next_state;
  end
  
  // 下一状态逻辑
  always @(*) begin
    case (state)
      IDLE: next_state = req ? BUSY : IDLE;
      BUSY: next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end
  
  // 输出逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      one_hot_out <= 8'h00;
      ack <= 1'b0;
    end
    else begin
      case (state)
        IDLE: begin
          if (req) begin
            one_hot_out <= (8'h01 << binary_in);
            ack <= 1'b1;  // 收到请求后立即确认
          end
          else begin
            ack <= 1'b0;
          end
        end
        
        BUSY: begin
          ack <= 1'b0;  // 完成一次传输后复位ack信号
        end
      endcase
    end
  end
  
endmodule