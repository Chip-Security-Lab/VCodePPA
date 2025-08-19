//SystemVerilog
module mipi_dsi_ecc_checker (
  input wire clk, reset_n,
  input wire [23:0] header_data,
  input wire [7:0] ecc_in,
  input wire header_valid,
  output reg ecc_error,
  output reg [7:0] ecc_calculated
);

  reg [7:0] parity_stage1;
  reg header_valid_stage1;
  reg [23:0] header_data_stage1;
  reg [7:0] ecc_in_stage1;
  reg header_valid_stage2;
  reg [7:0] parity_stage2;
  reg [7:0] ecc_in_stage2;

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
      parity_stage1 <= 8'h00;
      header_valid_stage1 <= 1'b0;
      header_data_stage1 <= 24'h0;
      ecc_in_stage1 <= 8'h00;
    end else begin
      header_valid_stage1 <= header_valid;
      header_data_stage1 <= header_data;
      ecc_in_stage1 <= ecc_in;
      
      case (header_valid)
        1'b1: begin
          parity_stage1[0] <= calc_parity(header_data, 8'b10101010);
          parity_stage1[1] <= calc_parity(header_data, 8'b01100110);
          parity_stage1[2] <= calc_parity(header_data, 8'b01010101);
          parity_stage1[3] <= calc_parity(header_data, 8'b11001100);
          parity_stage1[4] <= calc_parity(header_data, 8'b00111100);
          parity_stage1[5] <= calc_parity(header_data, 8'b11110000);
          parity_stage1[6] <= calc_parity(header_data, 8'b00001111);
          parity_stage1[7] <= ~(calc_parity(header_data, 8'b11111111));
        end
        default: parity_stage1 <= parity_stage1;
      endcase
    end
  end

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      parity_stage2 <= 8'h00;
      header_valid_stage2 <= 1'b0;
      ecc_in_stage2 <= 8'h00;
    end else begin
      header_valid_stage2 <= header_valid_stage1;
      parity_stage2 <= parity_stage1;
      ecc_in_stage2 <= ecc_in_stage1;
    end
  end

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ecc_error <= 1'b0;
      ecc_calculated <= 8'h00;
    end else begin
      case (header_valid_stage2)
        1'b1: begin
          ecc_calculated <= parity_stage2;
          ecc_error <= (parity_stage2 != ecc_in_stage2);
        end
        default: begin
          ecc_error <= ecc_error;
          ecc_calculated <= ecc_calculated;
        end
      endcase
    end
  end

endmodule