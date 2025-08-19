//SystemVerilog
module RD9(
  input  wire clk,
  input  wire aresetn,
  input  wire toggle_en,
  output reg  out_signal
);
  
  reg toggle_detected;
  
  // 检测toggle_en上升沿
  always @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
      toggle_detected <= 1'b0;
      out_signal     <= 1'b0;
    end
    else begin
      // 合并逻辑，减少寄存器数量和关键路径
      if (toggle_en && !toggle_detected)
        out_signal <= ~out_signal;
      
      toggle_detected <= toggle_en;
    end
  end
  
endmodule