module priority_parity_gen(
  input [15:0] data,
  input [3:0] priority_level,
  output parity_result
);
  reg [15:0] masked_data;
  integer i;
  
  always @(*) begin
    masked_data = 16'h0000;
    for (i = 0; i < 16; i = i + 1)
      if (i >= priority_level)
        masked_data[i] = data[i];
  end
  
  assign parity_result = ^masked_data;
endmodule