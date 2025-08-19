//SystemVerilog
module can_remote_frame_handler(
  input wire clk, rst_n,
  input wire rx_rtr, rx_id_valid,
  input wire [10:0] rx_id,
  output reg [10:0] tx_request_id,
  output reg tx_data_ready, tx_request
);
  // 响应ID和掩码存储
  reg [10:0] response_id [0:3];
  reg [3:0] response_mask;
  
  // 比较逻辑分解为更小的并行逻辑块
  wire stage1_valid;
  wire [3:0] id_match;
  wire match_found;
  wire [10:0] matched_id;
  
  // 将有效性判断提前计算并寄存
  reg rx_valid_stage1;
  
  // 流水线第二级信号
  reg match_found_stage2;
  reg [10:0] matched_id_stage2;
  reg stage2_valid;
  
  // 将输入有效性计算简化
  assign stage1_valid = rx_valid_stage1;
  
  // 并行化ID匹配逻辑，减少关键路径
  assign id_match[0] = response_mask[0] & (rx_id == response_id[0]);
  assign id_match[1] = response_mask[1] & (rx_id == response_id[1]);
  assign id_match[2] = response_mask[2] & (rx_id == response_id[2]);
  assign id_match[3] = response_mask[3] & (rx_id == response_id[3]);
  
  // 使用或运算简化匹配检测
  assign match_found = id_match[0] | id_match[1] | id_match[2] | id_match[3];
  
  // 优化ID选择的优先级编码器，减少关键路径延迟
  // 通过并行选择器结构替代嵌套三元运算符
  wire [10:0] matched_id_01 = id_match[0] ? response_id[0] : response_id[1];
  wire [10:0] matched_id_23 = id_match[2] ? response_id[2] : response_id[3];
  wire sel_01 = id_match[0] | id_match[1];
  wire sel_0123 = sel_01 ? 1'b1 : (id_match[2] | id_match[3]);
  
  assign matched_id = sel_01 ? matched_id_01 : 
                     (sel_0123 ? matched_id_23 : 11'h0);
  
  // 第一级流水线：输入寄存和配置
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 初始化响应mask和ID配置
      response_mask <= 4'b0101;
      response_id[0] <= 11'h100;
      response_id[1] <= 11'h200;
      response_id[2] <= 11'h300;
      response_id[3] <= 11'h400;
      
      // 重置输入寄存器
      rx_valid_stage1 <= 1'b0;
    end else begin
      // 寄存输入有效性信号，减轻后续阶段负担
      rx_valid_stage1 <= rx_id_valid & rx_rtr;
    end
  end
  
  // 第二级流水线：捕获比较结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      match_found_stage2 <= 1'b0;
      matched_id_stage2 <= 11'h0;
      stage2_valid <= 1'b0;
    end else begin
      stage2_valid <= stage1_valid;
      
      // 简化条件检测，减少路径延迟
      match_found_stage2 <= stage1_valid ? match_found : 1'b0;
      matched_id_stage2 <= stage1_valid ? matched_id : 11'h0;
    end
  end
  
  // 第三级流水线：输出生成
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_ready <= 1'b0;
      tx_request <= 1'b0;
      tx_request_id <= 11'h0;
    end else begin
      // 提前计算并分离输出有效性逻辑
      tx_request <= stage2_valid & match_found_stage2;
      
      // 优化并降低tx_data_ready的复位逻辑深度
      if (stage2_valid) begin
        tx_data_ready <= match_found_stage2 ? 1'b1 : tx_data_ready;
      end else begin
        tx_data_ready <= 1'b0;
      end
      
      // 分离ID更新逻辑，减少关键路径
      if (stage2_valid & match_found_stage2) begin
        tx_request_id <= matched_id_stage2;
      end
    end
  end
endmodule