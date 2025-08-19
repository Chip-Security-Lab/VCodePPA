//SystemVerilog
module mipi_csi_crc_generator (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire data_valid,
  input wire sot, eot,
  output reg [15:0] crc_out,
  output reg crc_valid
);
  reg [15:0] crc_reg;
  reg [1:0] state;  // Reduced from 4 bits to 2 bits
  
  // Optimized CRC-16-CCITT calculation
  function [15:0] update_crc;
    input [15:0] crc;
    input [7:0] data;
    reg [15:0] newcrc;
    reg [7:0] data_shifted;
    reg [15:0] crc_shifted;
    begin
      // Pre-calculate shifted values
      data_shifted = {data[6:0], 1'b0};
      crc_shifted = {crc[14:0], 1'b0};
      
      // Process all 8 bits in parallel
      newcrc = crc;
      if (crc[15] ^ data[7]) newcrc = crc_shifted ^ 16'h1021;
      else newcrc = crc_shifted;
      
      if (newcrc[15] ^ data[6]) newcrc = {newcrc[14:0], 1'b0} ^ 16'h1021;
      else newcrc = {newcrc[14:0], 1'b0};
      
      if (newcrc[15] ^ data[5]) newcrc = {newcrc[14:0], 1'b0} ^ 16'h1021;
      else newcrc = {newcrc[14:0], 1'b0};
      
      if (newcrc[15] ^ data[4]) newcrc = {newcrc[14:0], 1'b0} ^ 16'h1021;
      else newcrc = {newcrc[14:0], 1'b0};
      
      if (newcrc[15] ^ data[3]) newcrc = {newcrc[14:0], 1'b0} ^ 16'h1021;
      else newcrc = {newcrc[14:0], 1'b0};
      
      if (newcrc[15] ^ data[2]) newcrc = {newcrc[14:0], 1'b0} ^ 16'h1021;
      else newcrc = {newcrc[14:0], 1'b0};
      
      if (newcrc[15] ^ data[1]) newcrc = {newcrc[14:0], 1'b0} ^ 16'h1021;
      else newcrc = {newcrc[14:0], 1'b0};
      
      if (newcrc[15] ^ data[0]) newcrc = {newcrc[14:0], 1'b0} ^ 16'h1021;
      else newcrc = {newcrc[14:0], 1'b0};
      
      update_crc = newcrc;
    end
  endfunction
  
  // State encoding
  localparam IDLE = 2'b00;
  localparam ACTIVE = 2'b01;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      crc_reg <= 16'hFFFF;
      crc_valid <= 1'b0;
      state <= IDLE;
    end else begin
      crc_valid <= 1'b0;
      
      case (state)
        IDLE: begin
          if (sot) begin
            crc_reg <= 16'hFFFF;
            state <= ACTIVE;
          end
        end
        
        ACTIVE: begin
          if (data_valid) begin
            crc_reg <= update_crc(crc_reg, data_in);
          end
          
          if (eot) begin
            crc_out <= crc_reg;
            crc_valid <= 1'b1;
            state <= IDLE;
          end
        end
        
        default: state <= IDLE;
      endcase
    end
  end
endmodule