//SystemVerilog
module moore_3state_mem_write_ctrl #(parameter ADDR_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  output reg we,
  output reg [ADDR_WIDTH-1:0] addr,
  // 为Dadda乘法器添加的新端口
  input [1:0] multiplicand,
  input [1:0] multiplier,
  output [3:0] product
);
  reg [1:0] state, next_state;
  localparam IDLE    = 2'b00,
             SET_ADDR= 2'b01,
             WRITE   = 2'b10;

  // Dadda乘法器信号
  wire pp[0:1][0:1]; // 部分积矩阵
  wire s1, c1;       // 第一级加法器输出
  
  // 生成部分积
  assign pp[0][0] = multiplicand[0] & multiplier[0];
  assign pp[0][1] = multiplicand[0] & multiplier[1];
  assign pp[1][0] = multiplicand[1] & multiplier[0];
  assign pp[1][1] = multiplicand[1] & multiplier[1];
  
  // 组装结果 - 对于2位乘法器，Dadda结构相对简单
  // 部分积直接映射到结果的最低位
  assign product[0] = pp[0][0];
  
  // 使用半加器计算中间位
  assign s1 = pp[0][1] ^ pp[1][0];
  assign c1 = pp[0][1] & pp[1][0];
  assign product[1] = s1;
  
  // 计算高位
  assign product[2] = pp[1][1] ^ c1;
  assign product[3] = pp[1][1] & c1;

  // 原始状态机逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
      addr  <= 0;
    end else begin
      state <= next_state;
      if (next_state == SET_ADDR) addr <= addr + 1; // Adjusted to use next_state
    end
  end

  always @* begin
    we = 1'b0;
    case (state)
      IDLE:    next_state = start ? SET_ADDR : IDLE;
      SET_ADDR:next_state = WRITE;
      WRITE:   next_state = IDLE;
    endcase
    // Moore输出：只有在当前状态为WRITE时才置we=1
    if (next_state == WRITE) we = 1'b1; // Adjusted to use next_state
  end
endmodule