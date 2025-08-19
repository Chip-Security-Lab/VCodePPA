//SystemVerilog
module RD8 #(parameter SIZE=8)(
  input wire clk, 
  input wire rst,
  output reg [SIZE-1:0] ring
);

  reg [SIZE-1:0] next_ring;
  wire inv_control;
  reg [SIZE-1:0] rotated_value;
  
  // 条件反相逻辑
  assign inv_control = ring[SIZE-1];
  
  // 计算旋转值
  always @(*) begin
    rotated_value = {ring[SIZE-2:0], ring[SIZE-1]};
  end
  
  // 使用if-else替换条件运算符
  always @(*) begin
    if (inv_control) begin
      // 使用补码加法实现减法（对于条件反相的情况）
      next_ring = (~rotated_value) + 1'b1;
    end 
    else begin
      next_ring = rotated_value;
    end
  end
  
  always @(posedge clk) begin
    if (rst) begin
      ring <= {{(SIZE-1){1'b0}}, 1'b1}; // 复位时设置最低位为1
    end
    else begin
      ring <= next_ring;
    end
  end

endmodule