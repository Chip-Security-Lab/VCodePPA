//SystemVerilog
// 顶层模块
module reset_sync_sync_reset (
  input  wire clk,
  input  wire rst_n,
  output wire sync_rst
);
  
  wire stage1_out;
  
  // 第一级复位同步子模块
  reset_sync_stage1 u_stage1 (
    .clk       (clk),
    .rst_n     (rst_n),
    .stage_out (stage1_out)
  );
  
  // 第二级复位同步子模块
  reset_sync_stage2 u_stage2 (
    .clk       (clk),
    .rst_n     (rst_n),
    .stage_in  (stage1_out),
    .sync_rst  (sync_rst)
  );

endmodule

// 第一级复位同步子模块
module reset_sync_stage1 (
  input  wire clk,
  input  wire rst_n,
  output reg  stage_out
);
  
  always @(posedge clk or negedge rst_n) 
    if (!rst_n)
      stage_out <= 1'b0;
    else
      stage_out <= 1'b1;
  
endmodule

// 第二级复位同步子模块
module reset_sync_stage2 (
  input  wire clk,
  input  wire rst_n,
  input  wire stage_in,
  output reg  sync_rst
);
  
  always @(posedge clk or negedge rst_n)
    if (!rst_n)
      sync_rst <= 1'b0;
    else
      sync_rst <= stage_in;
  
endmodule