//SystemVerilog
module reset_sync_ring(
  input  wire clk,
  input  wire rst_n,
  output wire out_rst
);
  // 流水线级别寄存器
  reg [3:0] ring_stage1;
  reg [3:0] ring_stage2;
  reg [3:0] ring_stage3;
  reg [3:0] ring_stage4;
  
  // 流水线控制信号
  reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
  
  // 第一级流水线
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ring_stage1 <= 4'b1000;
      valid_stage1 <= 1'b0;
    end else begin
      ring_stage1 <= 4'b1000;  // 初始值始终是4'b1000
      valid_stage1 <= 1'b1;
    end
  end
  
  // 第二级流水线
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ring_stage2 <= 4'b0000;
      valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      ring_stage2 <= {ring_stage1[2:0], ring_stage1[3]};
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 第三级流水线
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ring_stage3 <= 4'b0000;
      valid_stage3 <= 1'b0;
    end else if (valid_stage2) begin
      ring_stage3 <= {ring_stage2[2:0], ring_stage2[3]};
      valid_stage3 <= valid_stage2;
    end
  end
  
  // 第四级流水线
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ring_stage4 <= 4'b0000;
      valid_stage4 <= 1'b0;
    end else if (valid_stage3) begin
      ring_stage4 <= {ring_stage3[2:0], ring_stage3[3]};
      valid_stage4 <= valid_stage3;
    end
  end
  
  // 输出逻辑
  assign out_rst = valid_stage4 ? ring_stage4[0] : 1'b0;
endmodule