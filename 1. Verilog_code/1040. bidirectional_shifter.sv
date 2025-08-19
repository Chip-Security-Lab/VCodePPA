module bidirectional_shifter #(parameter DATA_W=16) (
  input [DATA_W-1:0] data,
  input [$clog2(DATA_W)-1:0] amount,
  input left_not_right,   // Direction control
  input arithmetic_shift, // 1=arithmetic, 0=logical
  output [DATA_W-1:0] result
);
  reg [DATA_W-1:0] temp;
  
  always @(*) begin
    if (left_not_right)
      temp = data << amount;
    else if (arithmetic_shift)
      temp = $signed(data) >>> amount;
    else
      temp = data >> amount;
  end
  
  assign result = temp;
endmodule