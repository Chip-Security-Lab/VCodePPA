//SystemVerilog
module reset_startup_delay (
  input wire clk,
  input wire reset_n,
  output reg system_ready
);
  
  // 使用单个计数器替代多个阶段计数器
  reg [9:0] delay_counter; // 扩展位宽以覆盖所有阶段
  
  // 阶段完成指示器
  reg [3:0] stage_complete;
  
  // 各阶段阈值
  localparam [9:0] STAGE1_THRESHOLD = 10'h03F;
  localparam [9:0] STAGE2_THRESHOLD = 10'h0BF; // 0x3F + 0x80
  localparam [9:0] STAGE3_THRESHOLD = 10'h17F; // 0xBF + 0xC0
  localparam [9:0] STAGE4_THRESHOLD = 10'h27F; // 0x17F + 0x100
  
  // 计数器和阶段控制逻辑
  always @(posedge clk) begin
    if (!reset_n) begin
      delay_counter <= 10'h000;
      stage_complete <= 4'b0000;
      system_ready <= 1'b0;
    end
    else begin
      // 根据阈值检查更新阶段完成状态
      if (delay_counter <= STAGE4_THRESHOLD) begin
        delay_counter <= delay_counter + 1'b1;
        
        // 阶段1完成检查
        if (delay_counter == STAGE1_THRESHOLD)
          stage_complete[0] <= 1'b1;
          
        // 阶段2完成检查
        if (delay_counter == STAGE2_THRESHOLD && stage_complete[0])
          stage_complete[1] <= 1'b1;
          
        // 阶段3完成检查
        if (delay_counter == STAGE3_THRESHOLD && stage_complete[1])
          stage_complete[2] <= 1'b1;
          
        // 阶段4完成检查
        if (delay_counter == STAGE4_THRESHOLD && stage_complete[2]) begin
          stage_complete[3] <= 1'b1;
          system_ready <= 1'b1;
        end
      end
    end
  end
  
endmodule