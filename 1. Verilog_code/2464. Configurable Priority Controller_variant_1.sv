//SystemVerilog
module config_priority_intr_ctrl(
  input clk, async_rst_n, sync_rst,
  input [15:0] intr_sources,
  input [15:0] intr_mask,
  input [63:0] priority_config, // 4 bits per interrupt
  output reg [3:0] intr_id,
  output reg intr_active
);
  // 优化策略: 使用树状比较结构，减少流水线阶段并增加并行度
  reg [15:0] masked_src;
  reg [3:0] intr_priorities [0:15];
  reg [15:0] valid_intr; // 有效中断标志
  
  // 两阶段比较树
  reg [3:0] level1_pri [0:7];
  reg [3:0] level1_id [0:7];
  reg [7:0] level1_valid;
  
  reg [3:0] level2_pri [0:3];
  reg [3:0] level2_id [0:3];
  reg [3:0] level2_valid;
  
  reg [3:0] level3_pri [0:1];
  reg [3:0] level3_id [0:1];
  reg [1:0] level3_valid;
  
  reg [3:0] final_pri;
  reg [3:0] final_id;
  reg final_valid;
  
  integer i;
  
  // 第一阶段: 预处理 - 计算掩码源和有效中断
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      masked_src <= 16'd0;
      valid_intr <= 16'd0;
      for (i = 0; i < 16; i = i + 1)
        intr_priorities[i] <= 4'd0;
    end 
    else if (sync_rst) begin
      masked_src <= 16'd0;
      valid_intr <= 16'd0;
      for (i = 0; i < 16; i = i + 1)
        intr_priorities[i] <= 4'd0;
    end 
    else begin
      masked_src <= intr_sources & intr_mask;
      
      // 提取优先级并标记有效中断
      for (i = 0; i < 16; i = i + 1) begin
        intr_priorities[i] <= priority_config[i*4+:4];
        valid_intr[i] <= (intr_sources[i] & intr_mask[i]);
      end
    end
  end
  
  // 第二阶段: 第一级树比较 - 每对中断比较
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      for (i = 0; i < 8; i = i + 1) begin
        level1_pri[i] <= 4'hF;
        level1_id[i] <= 4'd0;
        level1_valid[i] <= 1'b0;
      end
    end 
    else if (sync_rst) begin
      for (i = 0; i < 8; i = i + 1) begin
        level1_pri[i] <= 4'hF;
        level1_id[i] <= 4'd0;
        level1_valid[i] <= 1'b0;
      end
    end 
    else begin
      for (i = 0; i < 8; i = i + 1) begin
        // 比较每一对中断(0vs1, 2vs3, ...)
        if (valid_intr[i*2] && valid_intr[i*2+1]) begin
          // 两个中断都有效，选优先级较高的（数值较小）
          if (intr_priorities[i*2] <= intr_priorities[i*2+1]) begin
            level1_pri[i] <= intr_priorities[i*2];
            level1_id[i] <= i*2;
          end else begin
            level1_pri[i] <= intr_priorities[i*2+1];
            level1_id[i] <= i*2+1;
          end
          level1_valid[i] <= 1'b1;
        end
        else if (valid_intr[i*2]) begin
          // 只有第一个中断有效
          level1_pri[i] <= intr_priorities[i*2];
          level1_id[i] <= i*2;
          level1_valid[i] <= 1'b1;
        end
        else if (valid_intr[i*2+1]) begin
          // 只有第二个中断有效
          level1_pri[i] <= intr_priorities[i*2+1];
          level1_id[i] <= i*2+1;
          level1_valid[i] <= 1'b1;
        end
        else begin
          // 两个中断都无效
          level1_pri[i] <= 4'hF;
          level1_id[i] <= 4'd0;
          level1_valid[i] <= 1'b0;
        end
      end
    end
  end
  
  // 第三阶段: 第二级树比较
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      for (i = 0; i < 4; i = i + 1) begin
        level2_pri[i] <= 4'hF;
        level2_id[i] <= 4'd0;
        level2_valid[i] <= 1'b0;
      end
    end 
    else if (sync_rst) begin
      for (i = 0; i < 4; i = i + 1) begin
        level2_pri[i] <= 4'hF;
        level2_id[i] <= 4'd0;
        level2_valid[i] <= 1'b0;
      end
    end 
    else begin
      for (i = 0; i < 4; i = i + 1) begin
        if (level1_valid[i*2] && level1_valid[i*2+1]) begin
          // 根据优先级数值(越小优先级越高)选择
          if (level1_pri[i*2] <= level1_pri[i*2+1]) begin
            level2_pri[i] <= level1_pri[i*2];
            level2_id[i] <= level1_id[i*2];
          end else begin
            level2_pri[i] <= level1_pri[i*2+1];
            level2_id[i] <= level1_id[i*2+1];
          end
          level2_valid[i] <= 1'b1;
        end
        else if (level1_valid[i*2]) begin
          level2_pri[i] <= level1_pri[i*2];
          level2_id[i] <= level1_id[i*2];
          level2_valid[i] <= 1'b1;
        end
        else if (level1_valid[i*2+1]) begin
          level2_pri[i] <= level1_pri[i*2+1];
          level2_id[i] <= level1_id[i*2+1];
          level2_valid[i] <= 1'b1;
        end
        else begin
          level2_pri[i] <= 4'hF;
          level2_id[i] <= 4'd0;
          level2_valid[i] <= 1'b0;
        end
      end
    end
  end
  
  // 第四阶段: 第三级树比较
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      for (i = 0; i < 2; i = i + 1) begin
        level3_pri[i] <= 4'hF;
        level3_id[i] <= 4'd0;
        level3_valid[i] <= 1'b0;
      end
    end 
    else if (sync_rst) begin
      for (i = 0; i < 2; i = i + 1) begin
        level3_pri[i] <= 4'hF;
        level3_id[i] <= 4'd0;
        level3_valid[i] <= 1'b0;
      end
    end 
    else begin
      for (i = 0; i < 2; i = i + 1) begin
        if (level2_valid[i*2] && level2_valid[i*2+1]) begin
          if (level2_pri[i*2] <= level2_pri[i*2+1]) begin
            level3_pri[i] <= level2_pri[i*2];
            level3_id[i] <= level2_id[i*2];
          end else begin
            level3_pri[i] <= level2_pri[i*2+1];
            level3_id[i] <= level2_id[i*2+1];
          end
          level3_valid[i] <= 1'b1;
        end
        else if (level2_valid[i*2]) begin
          level3_pri[i] <= level2_pri[i*2];
          level3_id[i] <= level2_id[i*2];
          level3_valid[i] <= 1'b1;
        end
        else if (level2_valid[i*2+1]) begin
          level3_pri[i] <= level2_pri[i*2+1];
          level3_id[i] <= level2_id[i*2+1];
          level3_valid[i] <= 1'b1;
        end
        else begin
          level3_pri[i] <= 4'hF;
          level3_id[i] <= 4'd0;
          level3_valid[i] <= 1'b0;
        end
      end
    end
  end
  
  // 第五阶段: 最终比较并准备输出
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      final_pri <= 4'hF;
      final_id <= 4'd0;
      final_valid <= 1'b0;
    end 
    else if (sync_rst) begin
      final_pri <= 4'hF;
      final_id <= 4'd0;
      final_valid <= 1'b0;
    end 
    else begin
      if (level3_valid[0] && level3_valid[1]) begin
        if (level3_pri[0] <= level3_pri[1]) begin
          final_pri <= level3_pri[0];
          final_id <= level3_id[0];
        end else begin
          final_pri <= level3_pri[1];
          final_id <= level3_id[1];
        end
        final_valid <= 1'b1;
      end
      else if (level3_valid[0]) begin
        final_pri <= level3_pri[0];
        final_id <= level3_id[0];
        final_valid <= 1'b1;
      end
      else if (level3_valid[1]) begin
        final_pri <= level3_pri[1];
        final_id <= level3_id[1];
        final_valid <= 1'b1;
      end
      else begin
        final_pri <= 4'hF;
        final_id <= 4'd0;
        final_valid <= 1'b0;
      end
    end
  end
  
  // 输出寄存器
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      intr_id <= 4'd0;
      intr_active <= 1'b0;
    end 
    else if (sync_rst) begin
      intr_id <= 4'd0;
      intr_active <= 1'b0;
    end 
    else begin
      intr_active <= final_valid;
      intr_id <= final_valid ? final_id : intr_id;
    end
  end
endmodule