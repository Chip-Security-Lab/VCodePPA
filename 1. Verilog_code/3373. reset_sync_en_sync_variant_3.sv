//SystemVerilog
module reset_sync_en_sync(
  input  wire clk,
  input  wire en,
  input  wire rst_n,
  output reg  rst_sync
);
  // 增加更多流水线级数以提高吞吐量
  reg stage1, stage2, stage3;
  // 为流水线各级添加控制信号
  reg valid_stage1, valid_stage2, valid_stage3;
  
  // 第一级流水线
  always @(posedge clk) begin
    if (!rst_n) begin
      stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end
    else if (en) begin
      stage1 <= 1'b1;
      valid_stage1 <= 1'b1;
    end
    else begin
      // 保持当前值
      valid_stage1 <= 1'b0;
    end
  end
  
  // 第二级流水线
  always @(posedge clk) begin
    if (!rst_n) begin
      stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end
    else if (en) begin
      stage2 <= stage1;
      valid_stage2 <= valid_stage1;
    end
    else begin
      // 保持当前值
      valid_stage2 <= 1'b0;
    end
  end
  
  // 第三级流水线
  always @(posedge clk) begin
    if (!rst_n) begin
      stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end
    else if (en) begin
      stage3 <= stage2;
      valid_stage3 <= valid_stage2;
    end
    else begin
      // 保持当前值
      valid_stage3 <= 1'b0;
    end
  end
  
  // 输出级
  always @(posedge clk) begin
    if (!rst_n) begin
      rst_sync <= 1'b0;
    end
    else if (en) begin
      rst_sync <= stage3 & valid_stage3;
    end
    // 当en=0时保持当前值
  end
endmodule