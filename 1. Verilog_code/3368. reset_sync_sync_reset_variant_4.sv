//SystemVerilog
module reset_sync_sync_reset(
  input  wire clk,    // 时钟输入
  input  wire rst_n,  // 异步低电平有效复位
  output wire sync_rst // 同步复位输出（改为wire类型）
);
  (* dont_touch = "true" *)        // 防止综合工具优化掉复位链
  (* async_reg = "true" *)         // 指示寄存器用于异步信号同步
  reg [1:0] rst_meta;              // 使用二位寄存器数组代替单独声明
  
  // 复位同步逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rst_meta <= 2'b00;           // 复位时清零所有同步寄存器
    end else begin
      rst_meta <= {rst_meta[0], 1'b1}; // 移位寄存器实现，更紧凑的代码
    end
  end
  
  // 连续赋值提高时序性能
  assign sync_rst = rst_meta[1];   // 输出使用连续赋值而非寄存器
  
endmodule