module async_logical_right_shifter #(
  parameter DATA_WIDTH = 16,
  parameter SHIFT_WIDTH = 4
)(
  input [DATA_WIDTH-1:0] in_data,
  input [SHIFT_WIDTH-1:0] shift_amount,
  output [DATA_WIDTH-1:0] out_data
);
  // Combinational shift right with zeros inserted from left
  assign out_data = in_data >> shift_amount;
endmodule