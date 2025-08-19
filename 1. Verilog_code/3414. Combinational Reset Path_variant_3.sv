//SystemVerilog
module RD4 #(parameter WIDTH=8)(
  input [WIDTH-1:0] in_data,
  input rst,
  output reg [WIDTH-1:0] out_data
);

  wire [WIDTH-1:0] complement_in;
  wire [WIDTH-1:0] neg_one;
  wire [WIDTH-1:0] subtracted_result;
  
  // 生成-1的补码表示
  assign neg_one = {WIDTH{1'b1}};
  
  // 计算输入数据的补码 (~in_data + 1)
  assign complement_in = (~in_data) + 1'b1;
  
  // 使用加法器实现减法: 0 - in_data = 0 + (~in_data + 1)
  assign subtracted_result = {WIDTH{1'b0}} + complement_in;
  
  always @(*) begin
    out_data = rst ? {WIDTH{1'b0}} : subtracted_result;
  end

endmodule