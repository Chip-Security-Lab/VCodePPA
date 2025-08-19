//SystemVerilog
module RD4 #(parameter WIDTH=8)(
  input [WIDTH-1:0] in_data,
  input rst,
  output reg [WIDTH-1:0] out_data
);
  reg [WIDTH-1:0] minuend;    // 被减数
  reg [WIDTH-1:0] subtrahend; // 减数
  reg subtract_enable;        // 减法使能
  reg [WIDTH-1:0] inverted_subtrahend; // 取反后的减数
  reg cin;                    // 进位输入
  
  always @(*) begin
    if (rst) begin
      out_data = {WIDTH{1'b0}};
    end else begin
      // 条件反相减法器实现
      minuend = in_data;
      subtrahend = {WIDTH{1'b0}}; // 减数为0（保持原值）
      subtract_enable = 1'b0;     // 不执行减法
      
      // 反相处理
      inverted_subtrahend = subtract_enable ? ~subtrahend : subtrahend;
      cin = subtract_enable ? 1'b1 : 1'b0;
      
      // 执行加法操作 (A + ~B + 1 或 A + B)
      {cin, out_data} = minuend + inverted_subtrahend + cin;
    end
  end
endmodule