module mipi_dsi_ecc_checker (
  input wire clk, reset_n,
  input wire [23:0] header_data,
  input wire [7:0] ecc_in,
  input wire header_valid,
  output reg ecc_error,
  output reg [7:0] ecc_calculated
);
  // DSI ECC (Error Correction Code) - Hamming(24,8)
  
  // Parity bit calculation function
  function calc_parity;
    input [23:0] data;
    input [7:0] bits;
    integer i;
    reg result;
    begin
      result = 0;
      for (i = 0; i < 24; i = i + 1)
        if (bits[i % 8])
          result = result ^ data[i];
      calc_parity = result;
    end
  endfunction
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ecc_error <= 1'b0;
      ecc_calculated <= 8'h00;
    end else if (header_valid) begin
      // Calculate ECC
      ecc_calculated[0] <= calc_parity(header_data, 8'b10101010);
      ecc_calculated[1] <= calc_parity(header_data, 8'b01100110);
      ecc_calculated[2] <= calc_parity(header_data, 8'b01010101);
      ecc_calculated[3] <= calc_parity(header_data, 8'b11001100);
      ecc_calculated[4] <= calc_parity(header_data, 8'b00111100);
      ecc_calculated[5] <= calc_parity(header_data, 8'b11110000);
      ecc_calculated[6] <= calc_parity(header_data, 8'b00001111);
      ecc_calculated[7] <= ~(calc_parity(header_data, 8'b11111111));
      
      ecc_error <= (ecc_calculated != ecc_in);
    end
  end
endmodule