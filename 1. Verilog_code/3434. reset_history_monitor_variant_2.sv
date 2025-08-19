//SystemVerilog
module reset_history_monitor (
  input wire clk,
  input wire reset_in,
  input wire clear,
  output reg [7:0] reset_history
);
  reg reset_in_d1;
  reg reset_in_d2;
  reg reset_edge_detected;
  
  // 合并所有基于时钟上升沿的always块
  always @(posedge clk) begin
    // 前移寄存器逻辑
    reset_in_d1 <= reset_in;
    reset_in_d2 <= reset_in_d1;
    reset_edge_detected <= reset_in_d1 && !reset_in_d2; // 检测上升沿
    
    // 历史记录逻辑
    if (clear)
      reset_history <= 8'h00;
    else if (reset_edge_detected)
      reset_history <= {reset_history[6:0], 1'b1};
  end
endmodule