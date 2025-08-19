//SystemVerilog
module carry_select_adder_3bit (
  input wire [2:0] data_a,
  input wire [2:0] data_b,
  output wire [3:0] summation
);

  wire carry_out_block0; // Carry out from the least significant bit (bit 0)

  // --- Block 0 (Bit 0) ---
  // This is effectively a half-adder stage as carry_in is implicitly 0
  assign summation[0] = data_a[0] ^ data_b[0];
  assign carry_out_block0 = data_a[0] & data_b[0];

  // --- Block 1 (Bits 2:1) ---
  // Pre-calculate sum and carry for bits 2:1 assuming carry_in_block1 = 0
  wire s0_1, c0_1; // Sum and carry for bit 1 assuming carry_in = 0
  wire s0_2, c0_2; // Sum and carry for bit 2 assuming carry_in = c0_1

  // Adder for bits 2:1 with carry_in = 0
  assign s0_1 = data_a[1] ^ data_b[1];
  assign c0_1 = data_a[1] & data_b[1];
  assign s0_2 = data_a[2] ^ data_b[2] ^ c0_1;
  assign c0_2 = (data_a[2] & data_b[2]) | (c0_1 & (data_a[2] ^ data_b[2]));

  // Pre-calculate sum and carry for bits 2:1 assuming carry_in_block1 = 1
  wire s1_1, c1_1; // Sum and carry for bit 1 assuming carry_in = 1
  wire s1_2, c1_2; // Sum and carry for bit 2 assuming carry_in = c1_1

  // Adder for bits 2:1 with carry_in = 1
  assign s1_1 = data_a[1] ^ data_b[1] ^ 1'b1;
  assign c1_1 = (data_a[1] & data_b[1]) | (1'b1 & (data_a[1] ^ data_b[1])); // Simplified: data_a[1] | data_b[1]
  assign s1_2 = data_a[2] ^ data_b[2] ^ c1_1;
  assign c1_2 = (data_a[2] & data_b[2]) | (c1_1 & (data_a[2] ^ data_b[2]));

  // Select the correct sum and carry for Block 1 based on the actual carry_out_block0
  assign summation[1] = carry_out_block0 ? s1_1 : s0_1;
  assign summation[2] = carry_out_block0 ? s1_2 : s0_2;
  assign summation[3] = carry_out_block0 ? c1_2 : c0_2; // The final carry out is the MSB of summation

endmodule