//SystemVerilog
module parity_calculator(
  input [15:0] data_word,
  output [3:0] parity_nibbles
);
  assign parity_nibbles[0] = ^data_word[3:0];
  assign parity_nibbles[1] = ^data_word[7:4];
  assign parity_nibbles[2] = ^data_word[11:8];
  assign parity_nibbles[3] = ^data_word[15:12];
endmodule

module parity_combiner(
  input [3:0] parity_nibbles,
  output [1:0] parity_bits
);
  assign parity_bits[0] = ^parity_nibbles[1:0];
  assign parity_bits[1] = ^parity_nibbles[3:2];
endmodule

module req_ack_handshake(
  input req,
  output ack
);
  reg ack_reg;
  reg req_reg;

  always @(posedge req) begin
    req_reg <= 1'b1;
    ack_reg <= 1'b0;
  end

  always @(posedge ack_reg) begin
    ack_reg <= 1'b1;
    req_reg <= 1'b0;
  end

  assign ack = ack_reg;
endmodule

module multi_bit_parity_req_ack(
  input [15:0] data_word,
  input req,
  output ack,
  output [1:0] parity_bits
);
  wire [3:0] parity_nibbles;

  parity_calculator parity_calc_inst(
    .data_word(data_word),
    .parity_nibbles(parity_nibbles)
  );

  parity_combiner parity_comb_inst(
    .parity_nibbles(parity_nibbles),
    .parity_bits(parity_bits)
  );

  req_ack_handshake handshake_inst(
    .req(req),
    .ack(ack)
  );
endmodule