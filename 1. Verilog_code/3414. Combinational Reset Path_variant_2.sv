//SystemVerilog
module RD4 #(
  parameter WIDTH = 4
)(
  input wire [WIDTH-1:0] in_data,
  input wire clk,         // 添加时钟信号
  input wire rst,
  output reg [WIDTH-1:0] out_data
);

  // 中间寄存器，用于分割数据路径
  reg [WIDTH-1:0] data_stage1;
  
  // 第一级流水线 - 输入处理
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      data_stage1 <= {WIDTH{1'b0}};
    end else begin
      data_stage1 <= in_data;
    end
  end
  
  // 第二级流水线 - 输出处理
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      out_data <= {WIDTH{1'b0}};
    end else begin
      out_data <= data_stage1;
    end
  end

endmodule