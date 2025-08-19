//SystemVerilog
module reset_glitch_detector (
  input wire clk,
  input wire reset_n,
  output reg glitch_detected
);
  reg reset_n_reg;
  
  always @(posedge clk) begin
    // 记录当前的reset_n值
    reset_n_reg <= reset_n;
    // 通过比较当前输入和上一个周期的寄存器值检测边沿
    glitch_detected <= reset_n ^ reset_n_reg;
  end
endmodule