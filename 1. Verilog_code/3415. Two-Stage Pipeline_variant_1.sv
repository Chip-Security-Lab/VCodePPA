//SystemVerilog
module RD5 #(parameter W=8)(
  input clk, input rst, input en,
  input [W-1:0] din,
  output reg [W-1:0] dout
);

  wire [W-1:0] stage1;
  wire [W-1:0] lut_result;
  reg [3:0] lut_addr;
  
  // LUT-based subtractor implementation
  always @(*) begin
    lut_addr = din[3:0]; // Use lower bits as LUT address
  end
  
  // Lookup table for subtraction assistance
  function [3:0] subtract_lut;
    input [3:0] addr;
    begin
      case(addr)
        4'b0000: subtract_lut = 4'b0000;
        4'b0001: subtract_lut = 4'b1111;
        4'b0010: subtract_lut = 4'b1110;
        4'b0011: subtract_lut = 4'b1101;
        4'b0100: subtract_lut = 4'b1100;
        4'b0101: subtract_lut = 4'b1011;
        4'b0110: subtract_lut = 4'b1010;
        4'b0111: subtract_lut = 4'b1001;
        4'b1000: subtract_lut = 4'b1000;
        4'b1001: subtract_lut = 4'b0111;
        4'b1010: subtract_lut = 4'b0110;
        4'b1011: subtract_lut = 4'b0101;
        4'b1100: subtract_lut = 4'b0100;
        4'b1101: subtract_lut = 4'b0011;
        4'b1110: subtract_lut = 4'b0010;
        4'b1111: subtract_lut = 4'b0001;
      endcase
    end
  endfunction
  
  // Combine LUT result with upper bits for full subtraction
  assign lut_result[3:0] = subtract_lut(lut_addr);
  assign lut_result[W-1:4] = din[W-1:4] - 1'b1; // Handle upper bits with adjustment
  
  // Final stage computation combining LUT and conventional subtraction
  assign stage1 = din[W-1:4] == 4'b0000 && din[3:0] == 4'b0000 ? 
                 din : lut_result;

  // Single pipeline register at the output
  always @(posedge clk) begin
    if (rst) begin
      dout <= 0;
    end else if (en) begin
      dout <= stage1;
    end
  end

endmodule