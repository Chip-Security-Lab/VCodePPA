module barrel_shifter_registered (
  input clk, enable,
  input [15:0] data,
  input [3:0] shift,
  input direction, // 0=right, 1=left
  output reg [15:0] shifted_data
);
  wire [15:0] temp;
  
  // Combinational barrel shifting logic
  assign temp = direction ? (data << shift) : (data >> shift);
  
  // Register the output
  always @(posedge clk) begin
    if (enable) shifted_data <= temp;
  end
endmodule