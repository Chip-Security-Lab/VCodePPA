//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_sync_5stage(
  input  wire clk,
  input  wire rst_n,
  output reg  synced_rst
);
  reg stage1, stage2, stage3, stage4;
  
  // 第一级复位同步逻辑
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      stage1 <= 1'b0;
    end else begin
      stage1 <= 1'b1;
    end
  end
  
  // 第二级复位同步逻辑
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      stage2 <= 1'b0;
    end else begin
      stage2 <= stage1;
    end
  end
  
  // 第三级复位同步逻辑
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      stage3 <= 1'b0;
    end else begin
      stage3 <= stage2;
    end
  end
  
  // 第四级复位同步逻辑
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      stage4 <= 1'b0;
    end else begin
      stage4 <= stage3;
    end
  end
  
  // 最终复位输出逻辑
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      synced_rst <= 1'b0;
    end else begin
      synced_rst <= stage4;
    end
  end
  
endmodule