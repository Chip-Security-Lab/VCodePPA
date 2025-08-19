//SystemVerilog
module level_triggered_intr_ctrl(
  input wire clock, reset_n,
  input wire [3:0] intr_level,
  input wire [3:0] intr_enable,
  output reg [1:0] intr_id,
  output reg intr_out
);
  // 内部信号声明
  reg [3:0] level_detect;
  wire [3:0] masked_interrupts;
  wire [1:0] priority_id;
  wire interrupt_active;
  
  // 组合逻辑部分 - 中断屏蔽
  assign masked_interrupts = intr_level & intr_enable;
  
  // 组合逻辑部分 - 中断激活检测
  assign interrupt_active = |masked_interrupts;
  
  // 组合逻辑部分 - 优先级编码器
  priority_encoder priority_logic(
    .intr_vector(masked_interrupts),
    .intr_id(priority_id)
  );
  
  // 时序逻辑部分
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      level_detect <= 4'h0;
      intr_id <= 2'h0;
      intr_out <= 1'b0;
    end 
    else begin
      level_detect <= masked_interrupts;
      intr_id <= priority_id;
      intr_out <= interrupt_active;
    end
  end
endmodule

// 优先级编码器模块 - 纯组合逻辑
module priority_encoder(
  input wire [3:0] intr_vector,
  output reg [1:0] intr_id
);
  // 优先级编码逻辑
  always @(*) begin
    if (intr_vector[0]) 
      intr_id = 2'd0;
    else if (intr_vector[1])
      intr_id = 2'd1;
    else if (intr_vector[2])
      intr_id = 2'd2;
    else if (intr_vector[3])
      intr_id = 2'd3;
    else
      intr_id = 2'd0;
  end
endmodule