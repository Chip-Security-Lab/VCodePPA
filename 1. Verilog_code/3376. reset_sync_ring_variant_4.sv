//SystemVerilog
module reset_sync_ring(
  input  wire clk,
  input  wire rst_n,
  output wire out_rst
);
  // 阶段间的连接信号
  wire [1:0] ring_stage1_next, ring_stage2_next, ring_stage3_next;
  wire [1:0] ring_stage4_next, ring_stage5_next, ring_stage6_next;
  wire valid_stage1_next, valid_stage2_next, valid_stage3_next;
  wire valid_stage4_next, valid_stage5_next, valid_stage6_next;
  wire out_rst_next;
  
  // 寄存器信号
  reg [1:0] ring_stage1, ring_stage2, ring_stage3;
  reg [1:0] ring_stage4, ring_stage5, ring_stage6;
  reg valid_stage1, valid_stage2, valid_stage3;
  reg valid_stage4, valid_stage5, valid_stage6;
  reg out_rst_r;
  
  // 组合逻辑部分 - 计算下一个状态
  assign ring_stage1_next = (!rst_n) ? 2'b10 : {ring_stage6[0], ring_stage6[1]};
  assign valid_stage1_next = (!rst_n) ? 1'b0 : 1'b1;
  
  assign ring_stage2_next = ring_stage1;
  assign valid_stage2_next = valid_stage1;
  
  assign ring_stage3_next = ring_stage2;
  assign valid_stage3_next = valid_stage2;
  
  assign ring_stage4_next = ring_stage3;
  assign valid_stage4_next = valid_stage3;
  
  assign ring_stage5_next = ring_stage4;
  assign valid_stage5_next = valid_stage4;
  
  assign ring_stage6_next = ring_stage5;
  assign valid_stage6_next = valid_stage5;
  
  assign out_rst_next = valid_stage6 ? ring_stage6[0] : 1'b0;
  
  // 时序逻辑部分 - 寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      // 异步复位时的初始值
      ring_stage1 <= 2'b10;
      ring_stage2 <= 2'b00;
      ring_stage3 <= 2'b00;
      ring_stage4 <= 2'b00;
      ring_stage5 <= 2'b00;
      ring_stage6 <= 2'b00;
      
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
      valid_stage3 <= 1'b0;
      valid_stage4 <= 1'b0;
      valid_stage5 <= 1'b0;
      valid_stage6 <= 1'b0;
      
      out_rst_r <= 1'b0;
    end
    else begin
      // 同步更新所有阶段
      ring_stage1 <= ring_stage1_next;
      ring_stage2 <= ring_stage2_next;
      ring_stage3 <= ring_stage3_next;
      ring_stage4 <= ring_stage4_next;
      ring_stage5 <= ring_stage5_next;
      ring_stage6 <= ring_stage6_next;
      
      valid_stage1 <= valid_stage1_next;
      valid_stage2 <= valid_stage2_next;
      valid_stage3 <= valid_stage3_next;
      valid_stage4 <= valid_stage4_next;
      valid_stage5 <= valid_stage5_next;
      valid_stage6 <= valid_stage6_next;
      
      out_rst_r <= out_rst_next;
    end
  end
  
  // 输出赋值
  assign out_rst = out_rst_r;
endmodule