//SystemVerilog
module can_error_counter(
  input wire clk, rst_n,
  input wire bit_error, stuff_error, form_error, crc_error, ack_error,
  input wire tx_success, rx_success,
  output reg [7:0] tx_err_count,
  output reg [7:0] rx_err_count,
  output reg bus_off
);
  // 错误检测信号流水线阶段
  wire any_error_stage0;
  reg any_error_stage1;
  
  // 成功传输信号流水线寄存器
  reg tx_success_stage1, rx_success_stage1;
  reg tx_success_stage2, rx_success_stage2;
  
  // 错误计数流水线寄存器
  reg [7:0] tx_err_count_stage1, rx_err_count_stage1;
  reg [7:0] tx_err_count_stage2, rx_err_count_stage2;
  
  // 错误计算中间结果
  reg [7:0] tx_dec_result_stage1, tx_inc_result_stage1;
  reg [7:0] rx_dec_result_stage1;
  
  // 错误计数预计算结果
  reg [7:0] next_tx_err_count_stage2;
  reg [7:0] next_rx_err_count_stage2;
  
  // 状态信号
  reg tx_dec_valid_stage1, tx_inc_valid_stage1;
  reg rx_dec_valid_stage1;
  
  // 总线关闭状态流水线寄存器
  reg next_bus_off_stage3;
  
  // 阶段0: 错误检测逻辑
  assign any_error_stage0 = bit_error || stuff_error || form_error || crc_error || ack_error;
  
  // 阶段1: 流水线寄存器更新和初步计算
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      any_error_stage1 <= 1'b0;
      tx_success_stage1 <= 1'b0;
      rx_success_stage1 <= 1'b0;
      tx_err_count_stage1 <= 8'h00;
      rx_err_count_stage1 <= 8'h00;
      
      // 错误计数变化预计算结果初始化
      tx_dec_result_stage1 <= 8'h00;
      tx_inc_result_stage1 <= 8'h00;
      rx_dec_result_stage1 <= 8'h00;
      
      // 状态信号初始化
      tx_dec_valid_stage1 <= 1'b0;
      tx_inc_valid_stage1 <= 1'b0;
      rx_dec_valid_stage1 <= 1'b0;
    end
    else begin
      any_error_stage1 <= any_error_stage0;
      tx_success_stage1 <= tx_success;
      rx_success_stage1 <= rx_success;
      tx_err_count_stage1 <= tx_err_count;
      rx_err_count_stage1 <= rx_err_count;
      
      // 错误计数变化预计算 - TX减少
      tx_dec_result_stage1 <= (tx_err_count > 0) ? tx_err_count - 1 : 8'h00;
      tx_dec_valid_stage1 <= tx_success;
      
      // 错误计数变化预计算 - TX增加
      tx_inc_result_stage1 <= (tx_err_count < 255) ? tx_err_count + 8 : 8'hFF;
      tx_inc_valid_stage1 <= any_error_stage0;
      
      // 错误计数变化预计算 - RX减少
      rx_dec_result_stage1 <= (rx_err_count > 0) ? rx_err_count - 1 : 8'h00;
      rx_dec_valid_stage1 <= rx_success;
    end
  end
  
  // 阶段2: 计算最终错误计数
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_success_stage2 <= 1'b0;
      rx_success_stage2 <= 1'b0;
      tx_err_count_stage2 <= 8'h00;
      rx_err_count_stage2 <= 8'h00;
      next_tx_err_count_stage2 <= 8'h00;
      next_rx_err_count_stage2 <= 8'h00;
    end
    else begin
      tx_success_stage2 <= tx_success_stage1;
      rx_success_stage2 <= rx_success_stage1;
      tx_err_count_stage2 <= tx_err_count_stage1;
      rx_err_count_stage2 <= rx_err_count_stage1;
      
      // TX错误计数最终结果选择
      if (tx_dec_valid_stage1)
        next_tx_err_count_stage2 <= tx_dec_result_stage1;
      else if (tx_inc_valid_stage1)
        next_tx_err_count_stage2 <= tx_inc_result_stage1;
      else
        next_tx_err_count_stage2 <= tx_err_count_stage1;
      
      // RX错误计数最终结果选择
      if (rx_dec_valid_stage1)
        next_rx_err_count_stage2 <= rx_dec_result_stage1;
      else
        next_rx_err_count_stage2 <= rx_err_count_stage1;
    end
  end
  
  // 阶段3: 计算总线关闭状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      next_bus_off_stage3 <= 1'b0;
    end
    else begin
      next_bus_off_stage3 <= (next_tx_err_count_stage2 >= 255);
    end
  end
  
  // 最终输出寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_err_count <= 8'h00;
      rx_err_count <= 8'h00;
      bus_off <= 1'b0;
    end
    else begin
      tx_err_count <= next_tx_err_count_stage2;
      rx_err_count <= next_rx_err_count_stage2;
      bus_off <= next_bus_off_stage3;
    end
  end
  
endmodule