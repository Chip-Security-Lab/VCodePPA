//SystemVerilog
module config_priority_intr_ctrl(
  input clk, async_rst_n, sync_rst,
  input [15:0] intr_sources,
  input [15:0] intr_mask,
  input [63:0] priority_config, // 4 bits per interrupt
  output reg [3:0] intr_id,
  output reg intr_active
);
  // 预解码优先级信息
  reg [15:0] masked_sources;
  reg [3:0] priority_levels [0:15];
  reg [3:0] highest_pri_level;
  reg [15:0] pri_level_match;
  integer i;
  
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      intr_id <= 4'd0;
      intr_active <= 1'b0;
    end else if (sync_rst) begin
      intr_id <= 4'd0;
      intr_active <= 1'b0;
    end else begin
      // 第一阶段：计算掩码源
      masked_sources = intr_sources & intr_mask;
      intr_active = |masked_sources;
      
      // 并行提取所有优先级
      for (i = 0; i < 16; i = i + 1) begin
        priority_levels[i] = priority_config[i*4+:4];
      end
      
      // 第二阶段：确定最高优先级
      highest_pri_level = 4'hF; // 初始设为最低优先级（值越小优先级越高）
      for (i = 0; i < 16; i = i + 1) begin
        if (masked_sources[i] && (priority_levels[i] < highest_pri_level)) begin
          highest_pri_level = priority_levels[i];
        end
      end
      
      // 第三阶段：选择优先级匹配的中断
      // 一次性比较所有中断的优先级是否匹配最高优先级
      for (i = 0; i < 16; i = i + 1) begin
        pri_level_match[i] = masked_sources[i] && (priority_levels[i] == highest_pri_level);
      end
      
      // 查找匹配中断中索引最低的（优先级相同时，低索引优先）
      intr_id = 4'd0; // 默认值
      casez (pri_level_match)
        16'b???????????????1: intr_id = 4'd0;
        16'b??????????????10: intr_id = 4'd1;
        16'b?????????????100: intr_id = 4'd2;
        16'b????????????1000: intr_id = 4'd3;
        16'b???????????10000: intr_id = 4'd4;
        16'b??????????100000: intr_id = 4'd5;
        16'b?????????1000000: intr_id = 4'd6;
        16'b????????10000000: intr_id = 4'd7;
        16'b???????100000000: intr_id = 4'd8;
        16'b??????1000000000: intr_id = 4'd9;
        16'b?????10000000000: intr_id = 4'd10;
        16'b????100000000000: intr_id = 4'd11;
        16'b???1000000000000: intr_id = 4'd12;
        16'b??10000000000000: intr_id = 4'd13;
        16'b?100000000000000: intr_id = 4'd14;
        16'b1000000000000000: intr_id = 4'd15;
        default: intr_id = 4'd0;
      endcase
    end
  end
endmodule