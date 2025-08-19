//SystemVerilog
module RD8 #(
  parameter SIZE = 4
)(
  input  wire            clk,    // 系统时钟
  input  wire            rst,    // 复位信号，高电平有效
  output wire [SIZE-1:0] ring    // 环形计数器输出
);

  // 内部信号定义
  reg [SIZE-1:0] ring_reg;       // 内部寄存器状态

  // 通过组合逻辑直接输出
  assign ring = {ring_reg[SIZE-2:0], ring_reg[SIZE-1]};

  // 时序逻辑部分 - 更新寄存器状态
  always @(posedge clk) begin
    if (rst) begin
      ring_reg <= {{SIZE-1{1'b0}}, 1'b1}; // 复位状态：最低位为1，其他位为0
    end else begin
      ring_reg <= ring_reg;                // 保持当前状态
    end
  end

endmodule