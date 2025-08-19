//SystemVerilog
module can_crc_generator(
  input wire clk, rst_n,
  input wire bit_in, bit_valid, crc_start,
  output wire [14:0] crc_out,
  output reg crc_error
);
  localparam [14:0] CRC_POLY = 15'h4599; // CAN CRC polynomial
  
  // 输入寄存器 - 将寄存器前移到组合逻辑之前
  reg bit_in_reg, bit_valid_reg, crc_start_reg;
  
  // 将输入信号寄存，减少输入到第一级逻辑的路径延迟
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_in_reg <= 1'b0;
      bit_valid_reg <= 1'b0;
      crc_start_reg <= 1'b0;
    end else begin
      bit_in_reg <= bit_in;
      bit_valid_reg <= bit_valid;
      crc_start_reg <= crc_start;
    end
  end
  
  reg [14:0] crc_reg;
  reg [14:0] crc_buf1;  // 简化为单级缓冲
  wire crc_next;
  
  // 优化的组合逻辑 - 提前计算crc_next，不使用时序逻辑
  assign crc_next = bit_in_reg ^ crc_reg[14];
  
  // 优化后的CRC计算逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_reg <= 15'h0;
      crc_error <= 1'b0;
    end else if (crc_start_reg) begin
      crc_reg <= 15'h0;
      crc_error <= 1'b0;
    end else if (bit_valid_reg) begin
      crc_reg <= crc_next ? ({crc_reg[13:0], 1'b0} ^ CRC_POLY) : {crc_reg[13:0], 1'b0};
      
      // 移动CRC错误检测逻辑，使其与CRC计算同步
      crc_error <= (crc_reg == 15'h0) ? 1'b0 : 1'b1;
    end
  end
  
  // 优化的输出缓冲区 - 减少关键路径上的负载
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_buf1 <= 15'h0;
    end else begin
      crc_buf1 <= crc_reg;
    end
  end
  
  // 使用缓冲输出减少关键路径上的负载
  assign crc_out = crc_buf1;
endmodule