//SystemVerilog
module hierarchical_intr_ctrl #(
  parameter GROUPS = 4,
  parameter SOURCES_PER_GROUP = 4
)(
  input clk, rst_n,
  input [GROUPS*SOURCES_PER_GROUP-1:0] intr_sources,
  input [GROUPS-1:0] group_mask,
  input [GROUPS*SOURCES_PER_GROUP-1:0] source_masks,
  output reg [$clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)-1:0] intr_id,
  output reg valid
);
  // 寄存输入信号，移动前端寄存器到输入端
  reg [GROUPS*SOURCES_PER_GROUP-1:0] intr_sources_reg;
  reg [GROUPS-1:0] group_mask_reg;
  reg [GROUPS*SOURCES_PER_GROUP-1:0] source_masks_reg;
  
  // 重整后的中间信号
  wire [GROUPS-1:0] group_active;
  wire [$clog2(SOURCES_PER_GROUP)-1:0] source_ids [0:GROUPS-1];
  reg [GROUPS-1:0] priority_group;
  
  // 寄存器化的中间结果
  reg [GROUPS-1:0] group_active_reg;
  reg [$clog2(SOURCES_PER_GROUP)-1:0] source_ids_reg [0:GROUPS-1];
  
  integer i, j;
  
  // 输入寄存器化 - 将寄存器移到输入端
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_sources_reg <= {(GROUPS*SOURCES_PER_GROUP){1'b0}};
      group_mask_reg <= {GROUPS{1'b0}};
      source_masks_reg <= {(GROUPS*SOURCES_PER_GROUP){1'b0}};
    end else begin
      intr_sources_reg <= intr_sources;
      group_mask_reg <= group_mask;
      source_masks_reg <= source_masks;
    end
  end
  
  // 使用寄存信号生成组活动信号
  genvar g;
  generate
    for (g = 0; g < GROUPS; g = g + 1) begin : group_gen
      wire [SOURCES_PER_GROUP-1:0] masked_sources;
      assign masked_sources = intr_sources_reg[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP] & 
                             source_masks_reg[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP];
      
      // 如果任何masked source激活且组未被屏蔽，则该组活动
      assign group_active[g] = |masked_sources & group_mask_reg[g];
    end
  endgenerate
  
  // 查找每个组内的最高优先级源
  // 将组合逻辑转为连续赋值以便优化
  generate
    for (g = 0; g < GROUPS; g = g + 1) begin : source_pri
      reg [$clog2(SOURCES_PER_GROUP)-1:0] pri_source;
      
      always @* begin
        pri_source = {$clog2(SOURCES_PER_GROUP){1'b0}};
        for (j = SOURCES_PER_GROUP-1; j >= 0; j = j - 1) begin
          if (intr_sources_reg[g*SOURCES_PER_GROUP+j] & source_masks_reg[g*SOURCES_PER_GROUP+j]) 
            pri_source = j[$clog2(SOURCES_PER_GROUP)-1:0];
        end
      end
      
      assign source_ids[g] = pri_source;
    end
  endgenerate
  
  // 计算优先级组合信号
  always @* begin
    priority_group = {GROUPS{1'b0}};
    for (i = GROUPS-1; i >= 0; i = i - 1) begin
      if (group_active[i]) begin
        priority_group[i] = 1'b1;
        // 使用阻塞赋值实现硬件中的优先级逻辑
        for (j = i-1; j >= 0; j = j - 1) begin
          priority_group[j] = 1'b0;
        end
      end
    end
  end
  
  // 中间结果寄存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      group_active_reg <= {GROUPS{1'b0}};
      for (i = 0; i < GROUPS; i = i + 1) begin
        source_ids_reg[i] <= {$clog2(SOURCES_PER_GROUP){1'b0}};
      end
    end else begin
      group_active_reg <= group_active;
      for (i = 0; i < GROUPS; i = i + 1) begin
        source_ids_reg[i] <= source_ids[i];
      end
    end
  end
  
  // 最终输出级，使用中间寄存的值
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= {($clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)){1'b0}};
      valid <= 1'b0;
    end else begin
      // 使用寄存的group_active信号确定valid
      valid <= |group_active_reg;
      
      // 默认输出
      intr_id <= {($clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)){1'b0}};
      
      // 使用组合逻辑计算优先级并选择正确的ID
      for (i = 0; i < GROUPS; i = i + 1) begin
        if (priority_group[i]) begin
          intr_id <= {i[$clog2(GROUPS)-1:0], source_ids_reg[i]};
        end
      end
    end
  end
endmodule