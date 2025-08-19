//SystemVerilog
module sync_odd_parity_gen(
  input clock, resetn,
  input [7:0] din,
  output p_out
);
  wire parity_bit;
  
  parity_calculator parity_calc_inst (
    .data_in(din),
    .parity_out(parity_bit)
  );
  
  parity_output_register out_reg_inst (
    .clock(clock),
    .resetn(resetn),
    .parity_in(parity_bit),
    .p_out(p_out)
  );
endmodule

module parity_calculator (
  input [7:0] data_in,
  output parity_out
);
  wire [7:0] xor_tree;
  
  assign xor_tree[0] = data_in[0];
  assign xor_tree[1] = xor_tree[0] ^ data_in[1];
  assign xor_tree[2] = xor_tree[1] ^ data_in[2];
  assign xor_tree[3] = xor_tree[2] ^ data_in[3];
  assign xor_tree[4] = xor_tree[3] ^ data_in[4];
  assign xor_tree[5] = xor_tree[4] ^ data_in[5];
  assign xor_tree[6] = xor_tree[5] ^ data_in[6];
  assign xor_tree[7] = xor_tree[6] ^ data_in[7];
  
  assign parity_out = ~xor_tree[7];
endmodule

module parity_output_register (
  input clock,
  input resetn,
  input parity_in,
  output reg p_out
);
  always @(posedge clock) begin
    if (!resetn) begin
      p_out <= 1'b0;
    end else begin
      p_out <= parity_in;
    end
  end
endmodule