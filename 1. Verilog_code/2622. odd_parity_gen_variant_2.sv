//SystemVerilog
module parity_calculator #(
  parameter WIDTH = 8
)(
  input [WIDTH-1:0] data,
  output even_parity
);
  // Parallel prefix XOR implementation
  wire [WIDTH-1:0] xor_tree [0:$clog2(WIDTH)];
  genvar i, j;
  
  // First level
  generate
    for (i = 0; i < WIDTH; i = i + 2) begin : first_level
      if (i + 1 < WIDTH) begin
        assign xor_tree[0][i/2] = data[i] ^ data[i+1];
      end else begin
        assign xor_tree[0][i/2] = data[i];
      end
    end
  endgenerate
  
  // Middle levels
  generate
    for (j = 1; j <= $clog2(WIDTH); j = j + 1) begin : middle_levels
      for (i = 0; i < (WIDTH >> j); i = i + 2) begin
        if (i + 1 < (WIDTH >> j)) begin
          assign xor_tree[j][i/2] = xor_tree[j-1][i] ^ xor_tree[j-1][i+1];
        end else begin
          assign xor_tree[j][i/2] = xor_tree[j-1][i];
        end
      end
    end
  endgenerate
  
  // Final output
  assign even_parity = xor_tree[$clog2(WIDTH)][0];
endmodule

module parity_inverter(
  input even_parity,
  output odd_parity
);
  assign odd_parity = ~even_parity;
endmodule

module odd_parity_gen #(
  parameter WIDTH = 8
)(
  input [WIDTH-1:0] data_input,
  output odd_parity
);
  wire parity_check;
  
  parity_calculator #(
    .WIDTH(WIDTH)
  ) calc_inst (
    .data(data_input),
    .even_parity(parity_check)
  );
  
  parity_inverter inv_inst (
    .even_parity(parity_check),
    .odd_parity(odd_parity)
  );
endmodule