//SystemVerilog
module RD5 #(parameter W=8)(
  input wire clk,
  input wire rst,
  input wire en,
  input wire [W-1:0] din,
  output reg [W-1:0] dout
);

  // 流水线寄存器 - 重定时后的结构
  reg [W-1:0] stage1_data;
  reg [W-1:0] stage2_data;
  
  // 流水线控制信号
  reg stage1_valid;
  reg stage2_valid;
  
  // 输入数据的缓存 - 为前向重定时添加
  wire [W-1:0] din_buffered;
  reg en_delayed;
  
  // 前向重定时：直接传递输入数据而不经过第一级寄存器
  assign din_buffered = din;
  
  always @(posedge clk) begin
    if (rst) begin
      // 复位所有流水线寄存器
      stage1_data <= {W{1'b0}};
      stage2_data <= {W{1'b0}};
      stage1_valid <= 1'b0;
      stage2_valid <= 1'b0;
      dout <= {W{1'b0}};
      en_delayed <= 1'b0;
    end else begin
      // 延迟使能信号
      en_delayed <= en;
      
      // 第一级流水线 - 现在直接使用输入数据
      if (en) begin
        stage1_data <= din_buffered;
        stage1_valid <= 1'b1;
      end else begin
        stage1_valid <= 1'b0;
      end
      
      // 第二级流水线
      stage2_data <= stage1_data;
      stage2_valid <= stage1_valid;
      
      // 输出级 - 现在可以在当前周期直接使用stage2_data
      if (stage2_valid) begin
        dout <= stage2_data;
      end
    end
  end

endmodule