//SystemVerilog
module RD2(
  input clk,
  input rst_n,
  input en,
  input [7:0] data_in,
  output reg [7:0] data_out
);
  // 流水线寄存器定义
  reg [7:0] stage1_data;
  reg stage1_valid;
  
  // 第一级流水线 - 输入寄存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_data <= 8'd0;
      stage1_valid <= 1'b0;
    end
    else begin
      stage1_data <= en ? data_in : stage1_data;
      stage1_valid <= en;
    end
  end
  
  // 第二级流水线 - 处理阶段与输出
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= 8'd0;
    end
    else if (stage1_valid) begin
      data_out <= stage1_data;
    end
  end
  
endmodule