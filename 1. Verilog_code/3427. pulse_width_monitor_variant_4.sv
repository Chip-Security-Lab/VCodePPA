//SystemVerilog
module pulse_width_monitor #(
  parameter MIN_WIDTH = 4
) (
  input wire clk,
  input wire reset_in,
  output reg reset_valid
);
  reg [$clog2(MIN_WIDTH)-1:0] width_counter;
  
  // 将reset_in_d移至输入后，而不是直接连接到输入
  reg reset_in_q;
  wire reset_in_d;
  
  // 为条件反相减法器添加的信号
  wire [$clog2(MIN_WIDTH)-1:0] target_width;
  wire [$clog2(MIN_WIDTH)-1:0] diff;
  wire borrow_out;
  
  // 设置目标宽度为MIN_WIDTH-1
  assign target_width = MIN_WIDTH-1;
  
  // 寄存输入信号，改善输入路径时序
  always @(posedge clk) begin
    reset_in_q <= reset_in;
  end
  
  // 将原有的组合逻辑放在寄存后的输入前
  assign reset_in_d = reset_in_q;
  
  // 条件反相减法器实现（4位宽度）
  // 使用条件反相算法: diff = ~width_counter + target_width + 1 (当target_width >= width_counter)
  // 或 diff = width_counter - target_width (当width_counter > target_width)
  assign {borrow_out, diff} = (width_counter > target_width) ? 
                             {1'b1, width_counter - target_width} : 
                             {1'b0, ~width_counter + target_width + 1'b1};
  
  always @(posedge clk) begin
    if (reset_in_d && !reset_in)
      width_counter <= 0;
    else if (reset_in_d)
      width_counter <= width_counter + 1;
    
    // 使用借位输出信号确定是否达到或超过MIN_WIDTH-1
    reset_valid <= borrow_out && reset_in_d;
  end
endmodule