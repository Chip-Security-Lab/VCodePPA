//SystemVerilog
module can_filter_bank #(
  parameter NUM_FILTERS = 4
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [NUM_FILTERS-1:0] filter_enable,
  input wire [10:0] filter_id [0:NUM_FILTERS-1],
  input wire [10:0] filter_mask [0:NUM_FILTERS-1],
  output reg id_match,
  output reg [NUM_FILTERS-1:0] match_filter
);
  // 组合逻辑信号
  wire [NUM_FILTERS-1:0] id_compare_result;
  wire [NUM_FILTERS-1:0] match_filter_comb;
  wire id_match_comb;
  
  // 组合逻辑电路：比较器和掩码计算
  filter_comparison_logic #(
    .NUM_FILTERS(NUM_FILTERS)
  ) filter_comp (
    .rx_id(rx_id),
    .filter_id(filter_id),
    .filter_mask(filter_mask),
    .filter_enable(filter_enable),
    .id_compare_result(id_compare_result),
    .match_filter_comb(match_filter_comb),
    .id_match_comb(id_match_comb)
  );
  
  // 时序逻辑电路：寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 1'b0;
      match_filter <= {NUM_FILTERS{1'b0}};
    end else if (id_valid) begin
      id_match <= id_match_comb;
      match_filter <= match_filter_comb;
    end
  end
endmodule

// 组合逻辑模块：处理所有的比较和掩码操作
module filter_comparison_logic #(
  parameter NUM_FILTERS = 4
)(
  input wire [10:0] rx_id,
  input wire [10:0] filter_id [0:NUM_FILTERS-1],
  input wire [10:0] filter_mask [0:NUM_FILTERS-1],
  input wire [NUM_FILTERS-1:0] filter_enable,
  output wire [NUM_FILTERS-1:0] id_compare_result,
  output wire [NUM_FILTERS-1:0] match_filter_comb,
  output wire id_match_comb
);
  // 组合逻辑中间信号
  wire [10:0] masked_rx_id [0:NUM_FILTERS-1];
  wire [10:0] masked_filter_id [0:NUM_FILTERS-1];
  
  // 掩码和比较生成
  genvar g;
  generate
    for (g = 0; g < NUM_FILTERS; g = g + 1) begin: comp_gen
      // 掩码操作
      assign masked_rx_id[g] = rx_id & filter_mask[g];
      assign masked_filter_id[g] = filter_id[g] & filter_mask[g];
      
      // 使用Kogge-Stone比较器进行比较
      kogge_stone_comparator ks_comp (
        .a(masked_rx_id[g]),
        .b(masked_filter_id[g]),
        .equal(id_compare_result[g])
      );
      
      // 计算每个过滤器的匹配结果
      assign match_filter_comb[g] = filter_enable[g] & id_compare_result[g];
    end
  endgenerate
  
  // 计算总体匹配结果
  assign id_match_comb = |match_filter_comb;
endmodule

// 优化的Kogge-Stone比较器模块
module kogge_stone_comparator (
  input wire [10:0] a,
  input wire [10:0] b,
  output wire equal
);
  // 第一阶段：计算每个位的相等性
  wire [10:0] eq_init;
  
  genvar i;
  generate
    for (i = 0; i < 11; i = i + 1) begin: init
      assign eq_init[i] = ~(a[i] ^ b[i]);
    end
  endgenerate
  
  // 第二阶段：Kogge-Stone并行前缀计算
  // 阶段1：1位前瞻
  wire [10:0] eq_s1;
  
  assign eq_s1[0] = eq_init[0];
  generate
    for (i = 1; i < 11; i = i + 1) begin: stage1
      assign eq_s1[i] = eq_init[i] & eq_init[i-1];
    end
  endgenerate
  
  // 阶段2：2位前瞻
  wire [10:0] eq_s2;
  
  assign eq_s2[0] = eq_s1[0];
  assign eq_s2[1] = eq_s1[1];
  generate
    for (i = 2; i < 11; i = i + 1) begin: stage2
      assign eq_s2[i] = eq_s1[i] & eq_s1[i-2];
    end
  endgenerate
  
  // 阶段3：4位前瞻
  wire [10:0] eq_s3;
  
  generate
    for (i = 0; i < 4; i = i + 1) begin: s3_keep
      assign eq_s3[i] = eq_s2[i];
    end
    for (i = 4; i < 11; i = i + 1) begin: stage3
      assign eq_s3[i] = eq_s2[i] & eq_s2[i-4];
    end
  endgenerate
  
  // 阶段4：8位前瞻（11位的最终阶段）
  wire [10:0] eq_final;
  
  generate
    for (i = 0; i < 8; i = i + 1) begin: s4_keep
      assign eq_final[i] = eq_s3[i];
    end
    for (i = 8; i < 11; i = i + 1) begin: stage4
      assign eq_final[i] = eq_s3[i] & eq_s3[i-8];
    end
  endgenerate
  
  // 最终的相等性是eq_final的所有位与操作
  assign equal = &eq_final;
endmodule