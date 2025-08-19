//SystemVerilog
module sequential_reset_controller (
  input wire clk,
  input wire rst_trigger,
  output reg [3:0] rst_vector
);
  localparam IDLE = 2'b00, RESET = 2'b01, RELEASE = 2'b10;
  
  reg [1:0] state;
  reg [2:0] step;
  
  // 为高扇出信号step添加多路缓冲寄存器，分散负载
  reg [2:0] step_buf_reset;    // 专用于RESET状态
  reg [2:0] step_buf_release;  // 专用于RELEASE状态
  reg [2:0] step_buf_common;   // 通用缓冲

  // 分组缓冲寄存器以平衡负载
  always @(posedge clk) begin
    step_buf_common <= step;
    step_buf_reset <= step_buf_common;
    step_buf_release <= step_buf_common;
  end
  
  // 状态机逻辑
  always @(posedge clk) begin
    case (state)
      IDLE: begin
        if (rst_trigger) begin
          state <= RESET;
          step <= 3'd0;
          rst_vector <= 4'b1111;
        end
      end
      
      RESET: begin
        if (step_buf_reset < 3'd4) begin
          step <= step + 3'd1;
        end else begin
          state <= RELEASE;
          step <= 3'd0;
        end
      end
      
      RELEASE: begin
        if (step_buf_release < 3'd4) begin
          rst_vector[step_buf_release] <= 1'b0;
          step <= step + 3'd1;
        end else begin
          state <= IDLE;
        end
      end
      
      default: state <= IDLE;
    endcase
  end
endmodule