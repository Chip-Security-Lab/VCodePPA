//SystemVerilog
module can_crc_generator(
  input wire clk, rst_n,
  input wire bit_in, bit_valid, crc_start,
  output wire [14:0] crc_out,
  output reg crc_error
);
  localparam [14:0] CRC_POLY = 15'h4599; // CAN CRC polynomial
  reg [14:0] crc_reg;
  wire crc_next;
  reg bit_in_r;
  reg bit_valid_r;
  reg crc_start_r;
  
  // 后向寄存器重定时：将输入信号寄存，减少关键路径
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_in_r <= 1'b0;
      bit_valid_r <= 1'b0;
      crc_start_r <= 1'b0;
    end else begin
      bit_in_r <= bit_in;
      bit_valid_r <= bit_valid;
      crc_start_r <= crc_start;
    end
  end
  
  // 将crc_next计算移到寄存器前
  assign crc_next = bit_in_r ^ crc_reg[14];
  
  // 预计算可能的下一个CRC值
  wire [14:0] crc_next_shifted = {crc_reg[13:0], 1'b0};
  wire [14:0] crc_next_xor = crc_next_shifted ^ CRC_POLY;
  
  // 移动寄存器到组合逻辑之前
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_reg <= 15'h0;
      crc_error <= 1'b0;
    end else if (crc_start_r) begin
      crc_reg <= 15'h0;
      crc_error <= 1'b0;
    end else if (bit_valid_r) begin
      // 选择预计算的CRC值，减少关键路径
      crc_reg <= crc_next ? crc_next_xor : crc_next_shifted;
      
      // CRC错误检测在寄存器后移，减少计算路径
      crc_error <= |crc_reg;
    end
  end
  
  assign crc_out = crc_reg;
endmodule