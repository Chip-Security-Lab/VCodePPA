//SystemVerilog
module priority_reset_detector(
  input  wire        clk,
  input  wire        enable,
  input  wire [7:0]  reset_sources,      // Active high
  input  wire [2:0]  priorities [7:0],   // Lower value = higher priority
  output reg  [2:0]  active_priority,
  output reg  [7:0]  priority_encoded,
  output reg         reset_out
);

  reg [2:0]  min_priority;
  reg [2:0]  min_index;
  reg        valid;
  integer    j;

  // 8-bit carry lookahead adder submodule
  function [7:0] cla_adder_8bit;
    input [7:0] a;
    input [7:0] b;
    input       cin;
    reg   [7:0] p, g;
    reg   [7:0] sum;
    reg   [8:0] carry;
    integer i;
    begin
      p = a ^ b;
      g = a & b;
      carry[0] = cin;
      for (i = 0; i < 8; i = i + 1) begin
        carry[i+1] = g[i] | (p[i] & carry[i]);
      end
      for (i = 0; i < 8; i = i + 1) begin
        sum[i] = p[i] ^ carry[i];
      end
      cla_adder_8bit = sum;
    end
  endfunction

  reg [7:0] encoded_priority_internal;

  always @(posedge clk) begin
    if (!enable) begin
      active_priority   <= 3'h7;
      priority_encoded  <= 8'h00;
      reset_out         <= 1'b0;
    end else begin
      min_priority = 3'h7;
      min_index    = 3'h0;
      valid        = 1'b0;

      for (j = 0; j < 8; j = j + 1) begin
        if (reset_sources[j]) begin
          if (!valid || (priorities[j] < min_priority)) begin
            min_priority = priorities[j];
            min_index    = j[2:0];
            valid        = 1'b1;
          end
        end
      end

      active_priority <= min_priority;

      // Use CLA adder to encode priority
      // (8'b1 << min_index) == 1 shifted left by min_index
      // So, do this via CLA adder: sum = 1 + (1 << min_index) - 1 = (1 << min_index)
      // But for demonstration, use CLA adder as (8'b0 + (8'b1 << min_index))
      encoded_priority_internal = cla_adder_8bit(8'b0, (valid ? (8'b1 << min_index) : 8'b0), 1'b0);

      priority_encoded <= encoded_priority_internal;
      reset_out        <= |reset_sources;
    end
  end

endmodule