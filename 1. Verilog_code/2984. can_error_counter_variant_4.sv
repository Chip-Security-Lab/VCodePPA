//SystemVerilog
module can_error_counter(
  input wire clk, rst_n,
  input wire bit_error, stuff_error, form_error, crc_error, ack_error,
  input wire tx_success, rx_success,
  output reg [7:0] tx_err_count,
  output reg [7:0] rx_err_count,
  output reg bus_off
);
  // 第一级流水线寄存器 - 输入信号寄存
  reg bit_error_stage1, stuff_error_stage1, form_error_stage1;
  reg crc_error_stage1, ack_error_stage1;
  reg tx_success_stage1, rx_success_stage1;
  
  // 第二级流水线寄存器 - 错误检测和聚合
  reg any_error_stage2;
  reg tx_success_stage2, rx_success_stage2;
  
  // 第三级流水线寄存器 - 计数器更新准备
  reg [7:0] tx_err_count_stage3;
  reg [7:0] rx_err_count_stage3;
  reg tx_inc_stage3, tx_dec_stage3, rx_dec_stage3;
  
  // 第四级流水线寄存器 - 计数器更新和总线状态计算
  reg [7:0] tx_err_count_next;
  reg [7:0] rx_err_count_next;
  reg bus_off_condition;
  
  // 第一级流水线 - 输入信号寄存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_error_stage1 <= 0;
      stuff_error_stage1 <= 0;
      form_error_stage1 <= 0;
      crc_error_stage1 <= 0;
      ack_error_stage1 <= 0;
      tx_success_stage1 <= 0;
      rx_success_stage1 <= 0;
    end else begin
      bit_error_stage1 <= bit_error;
      stuff_error_stage1 <= stuff_error;
      form_error_stage1 <= form_error;
      crc_error_stage1 <= crc_error;
      ack_error_stage1 <= ack_error;
      tx_success_stage1 <= tx_success;
      rx_success_stage1 <= rx_success;
    end
  end
  
  // 第二级流水线 - 错误检测和聚合
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      any_error_stage2 <= 0;
      tx_success_stage2 <= 0;
      rx_success_stage2 <= 0;
    end else begin
      any_error_stage2 <= bit_error_stage1 || stuff_error_stage1 || 
                          form_error_stage1 || crc_error_stage1 || 
                          ack_error_stage1;
      tx_success_stage2 <= tx_success_stage1;
      rx_success_stage2 <= rx_success_stage1;
    end
  end
  
  // 第三级流水线 - 计数器更新准备
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_err_count_stage3 <= 0;
      rx_err_count_stage3 <= 0;
      tx_inc_stage3 <= 0;
      tx_dec_stage3 <= 0;
      rx_dec_stage3 <= 0;
    end else begin
      tx_err_count_stage3 <= tx_err_count;
      rx_err_count_stage3 <= rx_err_count;
      tx_inc_stage3 <= any_error_stage2 && !tx_success_stage2;
      tx_dec_stage3 <= tx_success_stage2 && !any_error_stage2;
      rx_dec_stage3 <= rx_success_stage2;
    end
  end
  
  // 第四级流水线 - 计算新的计数器值和总线状态
  always @(*) begin
    // 默认保持当前值
    tx_err_count_next = tx_err_count_stage3;
    rx_err_count_next = rx_err_count_stage3;
    
    // 发送错误计数器逻辑
    if (tx_dec_stage3) begin
      tx_err_count_next = (tx_err_count_stage3 > 0) ? tx_err_count_stage3 - 1 : 0;
    end else if (tx_inc_stage3) begin
      if (tx_err_count_stage3 < 255) 
        tx_err_count_next = tx_err_count_stage3 + 8;
    end
    
    // 接收错误计数器逻辑
    if (rx_dec_stage3) begin
      rx_err_count_next = (rx_err_count_stage3 > 0) ? rx_err_count_stage3 - 1 : 0;
    end
    
    // 预计算总线关闭条件
    bus_off_condition = (tx_err_count_next >= 255);
  end
  
  // 最终寄存器更新阶段
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_err_count <= 0;
      rx_err_count <= 0;
      bus_off <= 0;
    end else begin
      tx_err_count <= tx_err_count_next;
      rx_err_count <= rx_err_count_next;
      bus_off <= bus_off_condition;
    end
  end
endmodule