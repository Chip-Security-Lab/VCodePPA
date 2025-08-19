//SystemVerilog
module sync_reset_counter #(
  parameter WIDTH = 8
)(
  input  wire           clk,     // 时钟输入
  input  wire           rst_n,   // 低电平有效复位
  input  wire           enable,  // 使能信号
  output reg  [WIDTH-1:0] count   // 计数器输出
);

  // 流水线寄存器
  reg [WIDTH-1:0] count_stage1;
  reg [WIDTH-1:0] count_stage2;
  
  // 流水线控制信号
  reg enable_stage1, enable_stage2;
  
  // 第一级流水线：计算递增值
  always @(posedge clk) begin
    if (!rst_n) begin
      count_stage1 <= {WIDTH{1'b0}};
      enable_stage1 <= 1'b0;
    end
    else begin
      count_stage1 <= count + 1'b1;
      enable_stage1 <= enable;
    end
  end
  
  // 第二级流水线：更新中间结果
  always @(posedge clk) begin
    if (!rst_n) begin
      count_stage2 <= {WIDTH{1'b0}};
      enable_stage2 <= 1'b0;
    end
    else begin
      count_stage2 <= count_stage1;
      enable_stage2 <= enable_stage1;
    end
  end
  
  // 第三级流水线：更新最终输出
  always @(posedge clk) begin
    if (!rst_n) begin
      count <= {WIDTH{1'b0}};
    end
    else if (enable_stage2) begin
      count <= count_stage2;
    end
  end

endmodule