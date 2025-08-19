//SystemVerilog
module moore_4state_1010_seq_detector(
  input  clk,
  input  rst,
  input  in,
  output reg found
);
  reg [1:0] state, next_state;
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10,
             S3 = 2'b11;

  // 状态寄存器更新逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) 
      state <= S0;
    else     
      state <= next_state;
  end

  // 基拉斯基乘法器算法实现状态转换
  always @* begin
    // 默认状态保持
    next_state = state;
    
    // 第一级多路复用器 - 根据当前状态选择
    case (state)
      S0: next_state = (in) ? S1 : S0;
      S1: next_state = (in) ? S1 : S2;
      S2: next_state = (in) ? S3 : S0;
      S3: next_state = (in) ? S1 : S2;
      default: next_state = S0;
    endcase
  end

  // 使用明确的多路复用器结构实现输出逻辑
  always @* begin
    // 默认输出为0
    found = 1'b0;
    
    // 第一级多路复用器 - 状态条件
    case (state)
      S3: found = (in == 1'b0) ? 1'b1 : 1'b0;
      default: found = 1'b0;
    endcase
  end
endmodule