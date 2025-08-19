module can_crc_generator(
  input wire clk, rst_n,
  input wire bit_in, bit_valid, crc_start,
  output wire [14:0] crc_out,
  output reg crc_error
);
  localparam [14:0] CRC_POLY = 15'h4599; // CAN CRC polynomial
  reg [14:0] crc_reg;
  reg crc_next;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_reg <= 15'h0;
      crc_error <= 0;
    end else if (crc_start) begin
      crc_reg <= 15'h0;
      crc_error <= 0;
    end else if (bit_valid) begin
      crc_next = bit_in ^ crc_reg[14];
      crc_reg <= {crc_reg[13:0], 1'b0};
      if (crc_next)
        crc_reg <= crc_reg ^ CRC_POLY;
        
      // 检查CRC错误条件
      crc_error <= (crc_reg == 15'h0) ? 1'b0 : 1'b1;
    end
  end
  
  assign crc_out = crc_reg;
endmodule