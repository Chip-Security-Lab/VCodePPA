//SystemVerilog
module reset_sync_shift #(
  parameter DEPTH = 3
)(
  input  wire clk,
  input  wire rst_n,
  output wire sync_out
);
  
  (* dont_touch = "true" *)
  (* shreg_extract = "no" *)
  reg [DEPTH-1:0] shift_reg;
  
  // 直接从寄存器获取输出信号
  assign sync_out = shift_reg[DEPTH-1];
  
  // 重置同步电路 - 已优化的寄存器结构
  // 第一级寄存器始终加载1，而不是从前一级移位
  // 这种方式将寄存器移动穿过组合逻辑，减少关键路径
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= {DEPTH{1'b0}};
    end
    else begin
      // 优化后的寄存器链 - 第一位直接赋值为1，减少关键路径
      shift_reg[0] <= 1'b1;
      // 其余位正常移位
      if (DEPTH > 1) begin
        shift_reg[DEPTH-1:1] <= shift_reg[DEPTH-2:0];
      end
    end
  end

endmodule