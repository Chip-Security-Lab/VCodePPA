//SystemVerilog
module mipi_cphy_deserializer (
  input wire clk,
  input wire reset_n,
  input wire [2:0] trio_in,
  output reg [7:0] data_out,
  output reg valid_out
);

  // Pipeline stage registers
  reg [2:0] symbol_buffer [0:5];
  reg [2:0] write_ptr, read_ptr;
  reg [3:0] decode_state;
  
  // Decoded data pipeline registers
  reg [1:0] decoded_symbols [0:3];
  reg [7:0] data_pipeline;
  reg valid_pipeline;
  
  // Symbol decoder function
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
  
  // Symbol capture pipeline stage
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      write_ptr <= 3'd0;
      read_ptr <= 3'd0;
      decode_state <= 4'b0001;
    end else begin
      symbol_buffer[write_ptr] <= trio_in;
      write_ptr <= write_ptr + 1'b1;
    end
  end
  
  // Decode pipeline stage
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      decode_state <= 4'b0001;
      valid_pipeline <= 1'b0;
    end else begin
      case (decode_state)
        4'b0001: begin
          if (write_ptr - read_ptr >= 3'd4) begin
            decode_state <= 4'b0010;
            decoded_symbols[0] <= decode_symbol(symbol_buffer[read_ptr]);
            decoded_symbols[1] <= decode_symbol(symbol_buffer[read_ptr+1]);
            decoded_symbols[2] <= decode_symbol(symbol_buffer[read_ptr+2]);
            decoded_symbols[3] <= decode_symbol(symbol_buffer[read_ptr+3]);
            read_ptr <= read_ptr + 3'd4;
          end
        end
        4'b0010: begin
          data_pipeline <= {decoded_symbols[0], decoded_symbols[1], 
                           decoded_symbols[2], decoded_symbols[3]};
          valid_pipeline <= 1'b1;
          decode_state <= 4'b0100;
        end
        4'b0100: begin
          valid_pipeline <= 1'b0;
          decode_state <= 4'b0001;
        end
        default: decode_state <= 4'b0001;
      endcase
    end
  end
  
  // Output pipeline stage
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_out <= 8'd0;
      valid_out <= 1'b0;
    end else begin
      data_out <= data_pipeline;
      valid_out <= valid_pipeline;
    end
  end
  
endmodule