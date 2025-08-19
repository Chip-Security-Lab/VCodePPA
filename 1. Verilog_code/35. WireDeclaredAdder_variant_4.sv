//SystemVerilog
module adder_8bit_rc (
  input wire [7:0] a,
  input wire [7:0] b,
  output wire [7:0] sum,
  output wire carry_out
);

  wire [8:0] carry; // carry[0] is carry_in (assumed 0), carry[i+1] is carry_out from bit i

  // Implicit carry_in = 0 for simple addition
  assign carry[0] = 1'b0;

  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin : bit_fa
      // Full adder logic for bit i
      // Sum bit
      assign sum[i] = a[i] ^ b[i] ^ carry[i];

      // Simplified Carry out logic using Boolean algebra:
      // (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i])
      // Simplified to: (a[i] & b[i]) | ((a[i] | b[i]) & carry[i])
      assign carry[i+1] = (a[i] & b[i]) | ((a[i] | b[i]) & carry[i]);
    end
  endgenerate

  // Carry out from the most significant bit (bit 7)
  assign carry_out = carry[8];

endmodule