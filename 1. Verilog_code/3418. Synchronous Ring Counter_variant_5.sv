//SystemVerilog
module RD8 #(parameter SIZE=8)(
  input wire clk,
  input wire rst,
  output wire [SIZE-1:0] ring
);
  
  // 内部寄存器信号
  reg [SIZE-1:0] ring_reg;
  
  // 连接输出到内部寄存器
  assign ring = ring_reg;
  
  // 实例化组合逻辑模块
  wire [SIZE-1:0] next_ring;
  RingShiftLogic #(.SIZE(SIZE)) shift_logic (
    .current_ring(ring_reg),
    .next_ring(next_ring)
  );
  
  // 时序逻辑 - 仅包含寄存器更新
  always @(posedge clk) begin
    if (rst) 
      ring_reg <= {{(SIZE-1){1'b0}}, 1'b1}; // 复位为只有最低位为1
    else
      ring_reg <= next_ring;
  end

endmodule

// 纯组合逻辑模块
module RingShiftLogic #(parameter SIZE=8)(
  input wire [SIZE-1:0] current_ring,
  output wire [SIZE-1:0] next_ring
);
  
  // 使用assign语句实现组合逻辑
  assign next_ring = {current_ring[SIZE-2:0], current_ring[SIZE-1]};
  
endmodule