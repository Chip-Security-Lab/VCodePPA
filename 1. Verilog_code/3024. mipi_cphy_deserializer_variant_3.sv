//SystemVerilog
module mipi_cphy_deserializer (
  input wire clk,
  input wire reset_n,
  input wire [2:0] trio_in,
  input wire ready_in,
  output reg [7:0] data_out,
  output reg valid_out
);

  // Stage 1: Symbol capture and buffer management
  reg [2:0] symbol_buffer [0:5];
  reg [2:0] write_ptr_stage1, read_ptr_stage1;
  reg [2:0] trio_in_stage1;
  
  // Stage 2: Symbol decoding
  reg [1:0] decoded_symbols_stage2 [0:3];
  reg [2:0] read_ptr_stage2;
  reg [2:0] write_ptr_stage2;
  reg [2:0] trio_in_stage2;
  
  // Stage 3: Data assembly
  reg [7:0] data_reg_stage3;
  reg valid_reg_stage3;
  reg [2:0] read_ptr_stage3;
  
  // Stage 4: Handshake
  reg [7:0] data_reg_stage4;
  reg valid_reg_stage4;
  
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

  // Stage 1: Symbol capture
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      write_ptr_stage1 <= 3'd0;
      read_ptr_stage1 <= 3'd0;
      trio_in_stage1 <= 3'd0;
    end else begin
      symbol_buffer[write_ptr_stage1] <= trio_in;
      write_ptr_stage1 <= write_ptr_stage1 + 1'b1;
      trio_in_stage1 <= trio_in;
    end
  end

  // Stage 2: Symbol decoding
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      read_ptr_stage2 <= 3'd0;
      write_ptr_stage2 <= 3'd0;
      trio_in_stage2 <= 3'd0;
    end else begin
      if (write_ptr_stage1 - read_ptr_stage1 >= 3'd4) begin
        decoded_symbols_stage2[0] <= decode_symbol(symbol_buffer[read_ptr_stage1]);
        decoded_symbols_stage2[1] <= decode_symbol(symbol_buffer[read_ptr_stage1+1]);
        decoded_symbols_stage2[2] <= decode_symbol(symbol_buffer[read_ptr_stage1+2]);
        decoded_symbols_stage2[3] <= decode_symbol(symbol_buffer[read_ptr_stage1+3]);
        read_ptr_stage2 <= read_ptr_stage1;
        write_ptr_stage2 <= write_ptr_stage1;
        read_ptr_stage1 <= read_ptr_stage1 + 3'd4;
      end
    end
  end

  // Stage 3: Data assembly
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_reg_stage3 <= 8'd0;
      valid_reg_stage3 <= 1'b0;
      read_ptr_stage3 <= 3'd0;
    end else begin
      if (write_ptr_stage2 - read_ptr_stage2 >= 3'd4) begin
        data_reg_stage3 <= {decoded_symbols_stage2[0], 
                           decoded_symbols_stage2[1],
                           decoded_symbols_stage2[2],
                           decoded_symbols_stage2[3]};
        valid_reg_stage3 <= 1'b1;
        read_ptr_stage3 <= read_ptr_stage2;
      end else begin
        valid_reg_stage3 <= 1'b0;
      end
    end
  end

  // Stage 4: Handshake
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_reg_stage4 <= 8'd0;
      valid_reg_stage4 <= 1'b0;
      data_out <= 8'd0;
      valid_out <= 1'b0;
    end else begin
      data_reg_stage4 <= data_reg_stage3;
      valid_reg_stage4 <= valid_reg_stage3;
      
      if (valid_reg_stage4 && ready_in) begin
        data_out <= data_reg_stage4;
        valid_out <= 1'b1;
      end else begin
        valid_out <= 1'b0;
      end
    end
  end

endmodule