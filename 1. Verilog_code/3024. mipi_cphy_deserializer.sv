module mipi_cphy_deserializer (
  input wire clk, reset_n,
  input wire [2:0] trio_in,
  output reg [7:0] data_out,
  output reg valid_out
);
  reg [2:0] symbol_buffer [0:5];
  reg [2:0] write_ptr, read_ptr;
  reg [1:0] decode_state;
  
  // Symbol to 2-bit mapping lookup
  function [1:0] decode_symbol;
    input [2:0] symbol;
    begin
      case (symbol)
        3'b001: decode_symbol = 2'b00;
        3'b011: decode_symbol = 2'b01;
        3'b101: decode_symbol = 2'b10;
        3'b111: decode_symbol = 2'b11;
        default: decode_symbol = 2'b00;
      endcase
    end
  endfunction
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      write_ptr <= 3'd0;
      read_ptr <= 3'd0;
      decode_state <= 2'd0;
      valid_out <= 1'b0;
    end else begin
      // Symbol capture
      symbol_buffer[write_ptr] <= trio_in;
      write_ptr <= write_ptr + 1'b1;
      
      // 4 symbols = 8 bits
      if (write_ptr - read_ptr >= 3'd4) begin
        data_out <= {decode_symbol(symbol_buffer[read_ptr]), 
                     decode_symbol(symbol_buffer[read_ptr+1]),
                     decode_symbol(symbol_buffer[read_ptr+2]),
                     decode_symbol(symbol_buffer[read_ptr+3])};
        read_ptr <= read_ptr + 3'd4;
        valid_out <= 1'b1;
      end else valid_out <= 1'b0;
    end
  end
endmodule