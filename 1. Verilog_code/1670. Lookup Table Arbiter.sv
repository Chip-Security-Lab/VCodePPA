module lut_arbiter(
  input clk, rst,
  input [3:0] request,
  output reg [3:0] grant
);
  reg [3:0] lut [0:15];
  
  always @(posedge clk) begin
    if (rst) begin
      // Initialize lookup table with pre-determined grants
      lut[0] <= 4'b0000; lut[1] <= 4'b0001; 
      lut[2] <= 4'b0010; lut[3] <= 4'b0001;
      // More initialization would follow
      grant <= 4'b0000;
    end else begin
      // Use request pattern as index into lookup table
      grant <= lut[request];
    end
  end
endmodule