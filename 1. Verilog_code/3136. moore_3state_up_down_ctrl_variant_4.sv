//SystemVerilog
module moore_3state_up_down_ctrl #(parameter DW = 8)(
  input  clk,
  input  rst,
  input  up_req,
  input  down_req,
  output reg direction  // 1=向上, 0=向下
);
  // 使用2位带符号乘法优化实现
  reg signed [1:0] state_vector;
  reg signed [1:0] next_state_product;

  localparam IDLE = 2'b00,
             UP   = 2'b01,
             DOWN = 2'b10;

  // 添加寄存器缓冲器以减少高扇出信号的延迟
  reg signed [1:0] state_vector_buf;
  reg signed [1:0] next_state_product_buf;

  // 注册状态矢量
  always @(posedge clk or posedge rst) begin
    if (rst) 
      state_vector_buf <= IDLE;
    else 
      state_vector_buf <= next_state_product_buf;
  end

  // 计算状态转换因子
  reg signed [1:0] up_factor;
  reg signed [1:0] down_factor;

  always @* begin
    up_factor = up_req ? 2'b01 : 2'b00;
    down_factor = down_req ? 2'b10 : 2'b00;
  end

  // 计算下一个状态
  always @* begin
    case (state_vector_buf)
      IDLE: begin
        if (up_req) 
          next_state_product_buf = UP;
        else if (down_req) 
          next_state_product_buf = DOWN;
        else 
          next_state_product_buf = IDLE;
      end
      UP: begin
        next_state_product_buf = (up_factor[0] * state_vector_buf[0]) ? UP : IDLE;
      end
      DOWN: begin
        next_state_product_buf = (down_factor[1] * state_vector_buf[1]) ? DOWN : IDLE;
      end
      default: next_state_product_buf = IDLE;
    endcase
  end

  // 输出逻辑
  always @* begin
    direction = (state_vector_buf == UP);
  end
endmodule