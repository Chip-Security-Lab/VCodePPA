//SystemVerilog
module level_triggered_intr_ctrl(
  input wire clock, reset_n,
  input wire [3:0] intr_level,
  input wire [3:0] intr_enable,
  input wire ready,
  output reg [1:0] intr_id,
  output reg valid,
  output reg [3:0] level_detect
);
  
  reg [3:0] enabled_intr;
  reg [1:0] next_intr_id;
  reg next_valid;
  
  // 将计算启用的中断逻辑提前到组合逻辑中
  always @(*) begin
    enabled_intr = intr_level & intr_enable;
    
    // 优先级编码逻辑移动到组合逻辑中
    if (|enabled_intr && ready) begin
      next_valid = 1'b1;
      
      casez (enabled_intr)
        4'b???1: next_intr_id = 2'd0;
        4'b??10: next_intr_id = 2'd1;
        4'b?100: next_intr_id = 2'd2;
        4'b1000: next_intr_id = 2'd3;
        default: next_intr_id = 2'd0;
      endcase
    end else if (|enabled_intr && !ready) begin
      next_valid = valid;
      next_intr_id = intr_id;
    end else begin
      next_valid = 1'b0;
      next_intr_id = intr_id;
    end
  end
  
  // 时序逻辑更新寄存器
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      level_detect <= 4'h0;
      intr_id <= 2'h0;
      valid <= 1'b0;
    end else begin
      level_detect <= enabled_intr;  // 使用预计算值
      intr_id <= next_intr_id;
      valid <= next_valid;
    end
  end
  
endmodule