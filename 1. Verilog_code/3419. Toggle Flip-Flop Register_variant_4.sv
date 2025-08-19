//SystemVerilog
module RD9 (
  input clk,
  input aresetn,
  input toggle_en,
  output reg out_signal
);

  // 移除了原始的流水线第一级寄存器，直接使用输入信号
  // 优化后的中间信号
  reg out_signal_next;
  
  // 计算阶段 - 直接基于输入信号计算
  always @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
      out_signal_next <= 1'b0;
    end else if (toggle_en) begin  // 直接使用toggle_en代替之前的toggle_en_stage1
      out_signal_next <= ~out_signal;
    end
  end

  // 输出寄存更新
  always @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
      out_signal <= 1'b0;
    end else begin
      out_signal <= out_signal_next;
    end
  end

endmodule