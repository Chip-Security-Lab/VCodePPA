//SystemVerilog
module mipi_dsi_ecc_checker (
  input wire clk, reset_n,
  input wire [23:0] header_data,
  input wire [7:0] ecc_in,
  input wire header_valid,
  output reg ecc_error,
  output reg [7:0] ecc_calculated
);

  // DSI ECC (Error Correction Code) - Hamming(24,8)
  localparam IDLE = 2'b00;
  localparam CALC = 2'b01;
  localparam CHECK = 2'b10;
  
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

  // Combinational logic for parity calculation
  wire [7:0] parity_bits_comb;
  assign parity_bits_comb[0] = calc_parity(header_data, 8'b10101010);
  assign parity_bits_comb[1] = calc_parity(header_data, 8'b01100110);
  assign parity_bits_comb[2] = calc_parity(header_data, 8'b01010101);
  assign parity_bits_comb[3] = calc_parity(header_data, 8'b11001100);
  assign parity_bits_comb[4] = calc_parity(header_data, 8'b00111100);
  assign parity_bits_comb[5] = calc_parity(header_data, 8'b11110000);
  assign parity_bits_comb[6] = calc_parity(header_data, 8'b00001111);
  assign parity_bits_comb[7] = ~(calc_parity(header_data, 8'b11111111));

  // State registers
  reg [1:0] state_reg;
  reg [7:0] parity_bits_reg;
  
  // Next state logic (combinational)
  wire [1:0] next_state;
  assign next_state = (state_reg == IDLE) ? (header_valid ? CALC : IDLE) :
                     (state_reg == CALC)  ? CHECK :
                     (state_reg == CHECK) ? IDLE : IDLE;

  // Sequential logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_reg <= IDLE;
      parity_bits_reg <= 8'h00;
      ecc_error <= 1'b0;
      ecc_calculated <= 8'h00;
    end else begin
      state_reg <= next_state;
      
      case (state_reg)
        CALC: begin
          parity_bits_reg <= parity_bits_comb;
          ecc_calculated <= parity_bits_comb;
        end
        CHECK: begin
          ecc_error <= (ecc_calculated != ecc_in);
        end
        default: begin
          // Hold previous values
        end
      endcase
    end
  end

endmodule