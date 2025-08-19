//SystemVerilog
module selective_bit_reset(
  input wire clk, rst_n,
  input wire reset_bit0, reset_bit1, reset_bit2,
  input wire [2:0] data_in,
  output reg [2:0] data_out
);
  
  // Stage 1: Input latching and bit reset logic
  reg [2:0] stage1_data;
  reg stage1_valid;
  wire [2:0] next_data;
  
  // Explicit multiplexer structure for each bit using case statements
  // Bit 0 multiplexer
  wire bit0_mux_out;
  assign bit0_mux_out = reset_bit0 ? 1'b0 : data_in[0];
  assign next_data[0] = bit0_mux_out;
  
  // Bit 1 multiplexer
  wire bit1_mux_out;
  assign bit1_mux_out = reset_bit1 ? 1'b0 : data_in[1];
  assign next_data[1] = bit1_mux_out;
  
  // Bit 2 multiplexer
  wire bit2_mux_out;
  assign bit2_mux_out = reset_bit2 ? 1'b0 : data_in[2];
  assign next_data[2] = bit2_mux_out;
  
  // Stage 1 registers with synchronous reset
  always @(posedge clk) begin
    if (!rst_n) begin
      stage1_data <= 3'b000;
      stage1_valid <= 1'b0;
    end
    else begin
      stage1_data <= next_data;
      stage1_valid <= 1'b1; // Always valid after reset
    end
  end
  
  // Stage 2: Output stage with enable logic
  wire stage2_enable;
  assign stage2_enable = stage1_valid;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      data_out <= 3'b000;
    end
    else if (stage2_enable) begin
      data_out <= stage1_data;
    end
  end
  
endmodule