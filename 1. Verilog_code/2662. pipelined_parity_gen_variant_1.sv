//SystemVerilog
module pipelined_parity_gen(
  input clk, rst_n,
  input [31:0] data_in,
  output reg parity_out
);

  parameter DATA_WIDTH = 32;
  parameter HALF_WIDTH = DATA_WIDTH/2;
  
  reg stage1_parity_lo, stage1_parity_hi;
  reg [3:0] stage1_data_lo, stage1_data_hi;
  
  function automatic parity_lut;
    input [3:0] nibble;
    begin
      parity_lut = nibble[0] ^ nibble[1] ^ nibble[2] ^ nibble[3];
    end
  endfunction

  // Stage 1: Data capture
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_data_lo <= 4'b0;
      stage1_data_hi <= 4'b0;
    end else begin
      stage1_data_lo <= data_in[3:0];
      stage1_data_hi <= data_in[7:4];
    end
  end

  // Stage 1: Parity calculation for lower nibbles
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_parity_lo <= 1'b0;
    end else begin
      stage1_parity_lo <= parity_lut(stage1_data_lo) ^ parity_lut(stage1_data_hi);
    end
  end

  // Stage 1: Parity calculation for upper nibbles
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_parity_hi <= 1'b0;
    end else begin
      stage1_parity_hi <= parity_lut(data_in[11:8]) ^ parity_lut(data_in[15:12]) ^
                         parity_lut(data_in[19:16]) ^ parity_lut(data_in[23:20]) ^
                         parity_lut(data_in[27:24]) ^ parity_lut(data_in[31:28]);
    end
  end

  // Stage 2: Final parity output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_out <= 1'b0;
    end else begin
      parity_out <= stage1_parity_lo ^ stage1_parity_hi;
    end
  end

endmodule