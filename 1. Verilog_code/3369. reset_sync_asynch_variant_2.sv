//SystemVerilog
module reset_sync_asynch(
  input  wire clk,
  input  wire arst_n,
  output reg  rst_sync
);
  // 使用两级寄存器同步链，增强亚稳态恢复能力
  wire rst_meta;
  reg rst_meta_reg;
  
  // 将rst_meta逻辑从组合逻辑中移出，单独处理，实现后向寄存器重定时
  assign rst_meta = 1'b1;
  
  // 第一级同步器
  always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      rst_meta_reg <= 1'b0;
    end else begin
      rst_meta_reg <= rst_meta;
    end
  end
  
  // 第二级同步器
  always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      rst_sync <= 1'b0;
    end else begin
      rst_sync <= rst_meta_reg;
    end
  end
endmodule