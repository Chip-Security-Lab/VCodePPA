//SystemVerilog
module can_id_matcher #(
  parameter NUM_PATTERNS = 8
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] match_patterns [0:NUM_PATTERNS-1],
  input wire [NUM_PATTERNS-1:0] pattern_enable,
  output wire id_match,
  output wire [NUM_PATTERNS-1:0] pattern_matched,
  output wire [7:0] match_index
);
  
  // 内部连接信号
  wire [NUM_PATTERNS-1:0] match_results_stage1;
  wire id_valid_stage1;
  wire any_match;
  
  // 第一阶段匹配模块实例化
  id_comparator #(
    .NUM_PATTERNS(NUM_PATTERNS)
  ) comparator_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_id(rx_id),
    .id_valid(id_valid),
    .match_patterns(match_patterns),
    .pattern_enable(pattern_enable),
    .match_results(match_results_stage1),
    .id_valid_out(id_valid_stage1)
  );
  
  // 匹配结果检测模块实例化
  match_detector match_detector_inst (
    .match_results(match_results_stage1),
    .any_match(any_match)
  );
  
  // 优先编码器和输出模块实例化
  priority_encoder_output #(
    .NUM_PATTERNS(NUM_PATTERNS)
  ) encoder_output_inst (
    .clk(clk),
    .rst_n(rst_n),
    .match_results(match_results_stage1),
    .id_valid(id_valid_stage1),
    .any_match(any_match),
    .id_match(id_match),
    .pattern_matched(pattern_matched),
    .match_index(match_index)
  );
  
endmodule

// 第一阶段：ID比较模块
module id_comparator #(
  parameter NUM_PATTERNS = 8
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] match_patterns [0:NUM_PATTERNS-1],
  input wire [NUM_PATTERNS-1:0] pattern_enable,
  output reg [NUM_PATTERNS-1:0] match_results,
  output reg id_valid_out
);
  
  integer i;
  
  // 执行ID比较，将结果存入流水线寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      match_results <= 0;
      id_valid_out <= 0;
    end else begin
      id_valid_out <= id_valid;
      for (i = 0; i < NUM_PATTERNS; i = i + 1) begin
        match_results[i] <= pattern_enable[i] && (rx_id == match_patterns[i]);
      end
    end
  end
  
endmodule

// 匹配结果检测模块
module match_detector (
  input wire [7:0] match_results,
  output wire any_match
);
  
  // 检测是否有任何匹配
  assign any_match = |match_results;
  
endmodule

// 优先编码器和输出处理模块
module priority_encoder_output #(
  parameter NUM_PATTERNS = 8
)(
  input wire clk, rst_n,
  input wire [NUM_PATTERNS-1:0] match_results,
  input wire id_valid,
  input wire any_match,
  output reg id_match,
  output reg [NUM_PATTERNS-1:0] pattern_matched,
  output reg [7:0] match_index
);
  
  // 优先编码器组合逻辑网络
  wire [7:0] encoded_index;
  
  // 优先级编码器组合逻辑 - 找到第一个匹配的索引
  assign encoded_index[0] = match_results[1] | match_results[3] | 
                           match_results[5] | match_results[7];
  assign encoded_index[1] = match_results[2] | match_results[3] | 
                           match_results[6] | match_results[7];
  assign encoded_index[2] = match_results[4] | match_results[5] | 
                           match_results[6] | match_results[7];
  assign encoded_index[7:3] = 0; // 高位置零
  
  // 生成最终输出
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 0;
      pattern_matched <= 0;
      match_index <= 0;
    end else if (id_valid) begin
      id_match <= any_match;
      pattern_matched <= match_results;
      
      // 如果有匹配，设置索引
      if (any_match) begin
        // 使用priority case找到最小的匹配索引
        casez (match_results)
          8'b????_???1: match_index <= 0;
          8'b????_??10: match_index <= 1;
          8'b????_?100: match_index <= 2;
          8'b????_1000: match_index <= 3;
          8'b???1_0000: match_index <= 4;
          8'b??10_0000: match_index <= 5;
          8'b?100_0000: match_index <= 6;
          8'b1000_0000: match_index <= 7;
          default:      match_index <= 0;
        endcase
      end else begin
        match_index <= 0;
      end
    end else begin
      id_match <= 0;
      pattern_matched <= 0;
      match_index <= 0;
    end
  end
  
endmodule