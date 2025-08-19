//SystemVerilog
module lut_arbiter(
  input clk,
  input rst,
  input [3:0] data_in,
  input valid_in,
  output reg ready_out,
  output reg [3:0] data_out,
  output reg valid_out,
  input ready_in
);

  // Use ROM instead of LUT for better area efficiency
  reg [3:0] grant_reg;
  reg data_valid;
  
  // Optimize the grant logic with a more efficient implementation
  always @(posedge clk) begin
    if (rst) begin
      grant_reg <= 4'b0000;
      data_valid <= 1'b0;
      ready_out <= 1'b1;
      valid_out <= 1'b0;
    end else begin
      // Optimize the handshaking logic
      if (valid_in && ready_out) begin
        // Direct mapping instead of LUT lookup for better performance
        case (data_in)
          4'b0000: grant_reg <= 4'b0000;
          4'b0001: grant_reg <= 4'b0001;
          4'b0010: grant_reg <= 4'b0010;
          4'b0011: grant_reg <= 4'b0001;
          4'b0100: grant_reg <= 4'b0000;
          4'b0101: grant_reg <= 4'b0001;
          4'b0110: grant_reg <= 4'b0010;
          4'b0111: grant_reg <= 4'b0001;
          4'b1000: grant_reg <= 4'b0000;
          4'b1001: grant_reg <= 4'b0001;
          4'b1010: grant_reg <= 4'b0010;
          4'b1011: grant_reg <= 4'b0001;
          4'b1100: grant_reg <= 4'b0000;
          4'b1101: grant_reg <= 4'b0001;
          4'b1110: grant_reg <= 4'b0010;
          4'b1111: grant_reg <= 4'b0001;
          default: grant_reg <= 4'b0000;
        endcase
        data_valid <= 1'b1;
        ready_out <= 1'b0;
      end
      
      if (data_valid && ready_in) begin
        data_out <= grant_reg;
        valid_out <= 1'b1;
        ready_out <= 1'b1;
        data_valid <= 1'b0;
      end else begin
        valid_out <= 1'b0;
      end
    end
  end
endmodule