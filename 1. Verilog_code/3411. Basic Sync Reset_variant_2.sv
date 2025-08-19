//SystemVerilog
module RD1 #(parameter DW=8)(
  input clk, 
  input rst,
  input [DW-1:0] din,
  output reg [DW-1:0] dout
);
  // 内部信号定义
  reg [DW-1:0] sub_result;
  reg [DW-1:0] complement;
  reg sub_flag;
  reg [DW-1:0] din_inverse;
  reg [DW-1:0] din_plus_one;
  
  // 条件反相减法器算法实现 - 使用显式多路复用器结构
  always @(*) begin
    // 确定是否需要进行减法操作
    sub_flag = |din;
    
    // 计算反相
    din_inverse = ~din;
    
    // 计算反相加1
    din_plus_one = din_inverse + 1'b1;
    
    // 计算二进制补码 - 显式多路复用器
    case(sub_flag)
      1'b1: complement = din_plus_one;
      1'b0: complement = din;
    endcase
    
    // 最终减法结果 - 显式多路复用器
    case(sub_flag)
      1'b1: sub_result = complement;
      1'b0: sub_result = din;
    endcase
  end
  
  // 时序逻辑，更新输出寄存器
  always @(posedge clk) begin
    if (rst) 
      dout <= {DW{1'b0}};
    else 
      dout <= sub_result;
  end
endmodule