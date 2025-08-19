//SystemVerilog
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

  // Carry lookahead adder for pointer calculations
  wire [2:0] write_ptr_next;
  wire [2:0] read_ptr_next;
  wire [2:0] write_ptr_plus_1;
  wire [2:0] read_ptr_plus_4;
  
  // Generate and propagate signals
  wire [2:0] g_write, p_write;
  wire [2:0] g_read, p_read;
  
  // Write pointer lookahead logic
  assign g_write[0] = write_ptr[0];
  assign p_write[0] = 1'b1;
  assign g_write[1] = write_ptr[1] & write_ptr[0];
  assign p_write[1] = write_ptr[1] | write_ptr[0];
  assign g_write[2] = write_ptr[2] & (write_ptr[1] | write_ptr[0]);
  assign p_write[2] = write_ptr[2] | (write_ptr[1] | write_ptr[0]);
  
  // Read pointer lookahead logic
  assign g_read[0] = read_ptr[0];
  assign p_read[0] = 1'b1;
  assign g_read[1] = read_ptr[1] & read_ptr[0];
  assign p_read[1] = read_ptr[1] | read_ptr[0];
  assign g_read[2] = read_ptr[2] & (read_ptr[1] | read_ptr[0]);
  assign p_read[2] = read_ptr[2] | (read_ptr[1] | read_ptr[0]);
  
  // Calculate next pointers
  assign write_ptr_plus_1 = {g_write[2], g_write[1], g_write[0]} ^ {p_write[2], p_write[1], p_write[0]};
  assign read_ptr_plus_4 = {g_read[2], g_read[1], g_read[0]} ^ {p_read[2], p_read[1], p_read[0]};
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      write_ptr <= 3'd0;
      read_ptr <= 3'd0;
      decode_state <= 2'd0;
      valid_out <= 1'b0;
    end else begin
      // Symbol capture
      symbol_buffer[write_ptr] <= trio_in;
      write_ptr <= write_ptr_plus_1;
      
      // 4 symbols = 8 bits
      if (write_ptr - read_ptr >= 3'd4) begin
        data_out <= {decode_symbol(symbol_buffer[read_ptr]), 
                     decode_symbol(symbol_buffer[read_ptr+1]),
                     decode_symbol(symbol_buffer[read_ptr+2]),
                     decode_symbol(symbol_buffer[read_ptr+3])};
        read_ptr <= read_ptr_plus_4;
        valid_out <= 1'b1;
      end else valid_out <= 1'b0;
    end
  end
endmodule