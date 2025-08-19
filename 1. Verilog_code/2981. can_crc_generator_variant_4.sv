//SystemVerilog
module can_crc_generator(
  input wire clk, rst_n,
  input wire bit_in, bit_valid, crc_start,
  output wire [14:0] crc_out,
  output reg crc_error
);
  localparam [14:0] CRC_POLY = 15'h4599; // CAN CRC polynomial
  
  // 流水线寄存器定义
  reg [14:0] crc_reg_stage1, crc_reg_stage2, crc_reg_stage3, crc_reg_stage4;
  
  // 流水线控制信号
  reg bit_valid_stage1, bit_valid_stage2, bit_valid_stage3;
  reg bit_in_stage1, bit_in_stage2;
  reg crc_start_stage1, crc_start_stage2, crc_start_stage3;
  
  // 中间计算结果
  reg crc_next_bit_stage2;
  reg [14:0] crc_shifted_stage2;
  reg [14:0] crc_xor_stage2;
  reg [14:0] crc_next_stage3;
  
  // 第一级流水线 - 寄存输入信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_valid_stage1 <= 1'b0;
      bit_in_stage1 <= 1'b0;
      crc_start_stage1 <= 1'b0;
      crc_reg_stage1 <= 15'h0;
    end else begin
      bit_valid_stage1 <= bit_valid;
      bit_in_stage1 <= bit_in;
      crc_start_stage1 <= crc_start;
      
      if (crc_start)
        crc_reg_stage1 <= 15'h0;
      else if (bit_valid)
        crc_reg_stage1 <= crc_reg_stage4;
    end
  end
  
  // 第二级流水线 - 计算XOR和移位操作的准备
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_valid_stage2 <= 1'b0;
      bit_in_stage2 <= 1'b0;
      crc_start_stage2 <= 1'b0;
      crc_next_bit_stage2 <= 1'b0;
      crc_shifted_stage2 <= 15'h0;
      crc_xor_stage2 <= 15'h0;
      crc_reg_stage2 <= 15'h0;
    end else begin
      bit_valid_stage2 <= bit_valid_stage1;
      bit_in_stage2 <= bit_in_stage1;
      crc_start_stage2 <= crc_start_stage1;
      crc_reg_stage2 <= crc_start_stage1 ? 15'h0 : crc_reg_stage1;
      
      // 计算XOR的输入位
      crc_next_bit_stage2 <= bit_in_stage1 ^ crc_reg_stage1[14];
      
      // 准备移位后的CRC和XOR掩码
      crc_shifted_stage2 <= {crc_reg_stage1[13:0], 1'b0};
      crc_xor_stage2 <= {crc_reg_stage1[13:0], 1'b0} ^ CRC_POLY;
    end
  end
  
  // 第三级流水线 - 完成CRC计算
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_valid_stage3 <= 1'b0;
      crc_start_stage3 <= 1'b0;
      crc_next_stage3 <= 15'h0;
      crc_reg_stage3 <= 15'h0;
    end else begin
      bit_valid_stage3 <= bit_valid_stage2;
      crc_start_stage3 <= crc_start_stage2;
      crc_reg_stage3 <= crc_start_stage2 ? 15'h0 : crc_reg_stage2;
      
      // 根据next_bit选择适当的CRC值
      if (bit_valid_stage2)
        crc_next_stage3 <= crc_next_bit_stage2 ? crc_xor_stage2 : crc_shifted_stage2;
    end
  end
  
  // 第四级流水线 - 最终CRC结果和错误检测
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_reg_stage4 <= 15'h0;
      crc_error <= 1'b0;
    end else begin
      if (crc_start_stage3)
        crc_reg_stage4 <= 15'h0;
      else if (bit_valid_stage3)
        crc_reg_stage4 <= crc_next_stage3;
      
      // 错误检测逻辑
      if (bit_valid_stage3) begin
        if (crc_reg_stage3 == 15'h0)
          crc_error <= 1'b0;
        else if (crc_next_stage3 == 15'h0)
          crc_error <= 1'b0;
        else
          crc_error <= 1'b1;
      end
    end
  end
  
  // 输出当前CRC值
  assign crc_out = crc_reg_stage4;
endmodule