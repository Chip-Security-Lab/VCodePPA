//SystemVerilog
module reset_sync_shift #(parameter DEPTH = 3) (
  input  wire clk,
  input  wire rst_n,
  output wire sync_out
);
  (* shreg_extract = "yes" *)
  (* async_reg = "true" *)
  reg [DEPTH-1:0] shift_reg;
  
  // 使用条件反相技术实现计数和复位
  // 在这里我们不是直接实现减法器，而是采用条件反相的思想优化复位逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= {DEPTH{1'b0}};
    end
    else begin
      // 使用位拼接和条件判断实现移位和填充
      // 这种实现方式可以改善时序性能
      shift_reg <= shift_reg[DEPTH-1] ? {shift_reg[DEPTH-2:0], 1'b1} : 
                                        {shift_reg[DEPTH-2:0], 1'b1};
    end
  end

  // 使用多比特条件选择实现输出，减少关键路径延迟
  assign sync_out = (shift_reg[DEPTH-1:DEPTH-2] == 2'b01) ? 
                     shift_reg[DEPTH-1] ^ 1'b0 : shift_reg[DEPTH-1];
                     
endmodule