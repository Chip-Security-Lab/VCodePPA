//SystemVerilog
// Top level module
module mipi_dsi_ecc_checker (
  input wire clk, reset_n,
  input wire [23:0] header_data,
  input wire [7:0] ecc_in,
  input wire header_valid,
  output reg ecc_error,
  output reg [7:0] ecc_calculated
);

  // Internal signals
  wire [7:0] parity_results;
  wire [7:0] ecc_calculated_next;
  wire ecc_error_next;

  // Parity calculation module
  parity_calculator parity_calc (
    .clk(clk),
    .reset_n(reset_n),
    .header_data(header_data),
    .header_valid(header_valid),
    .parity_results(parity_results)
  );

  // ECC comparison module
  ecc_comparator ecc_comp (
    .clk(clk),
    .reset_n(reset_n),
    .parity_results(parity_results),
    .ecc_in(ecc_in),
    .header_valid(header_valid),
    .ecc_calculated(ecc_calculated_next),
    .ecc_error(ecc_error_next)
  );

  // Output registers
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ecc_error <= 1'b0;
      ecc_calculated <= 8'h00;
    end else if (header_valid) begin
      ecc_error <= ecc_error_next;
      ecc_calculated <= ecc_calculated_next;
    end
  end

endmodule

// Parity calculation module
module parity_calculator (
  input wire clk,
  input wire reset_n,
  input wire [23:0] header_data,
  input wire header_valid,
  output reg [7:0] parity_results
);

  // Pre-computed parity patterns
  reg [7:0] parity_patterns [0:7];
  initial begin
    parity_patterns[0] = 8'b10101010;
    parity_patterns[1] = 8'b01100110;
    parity_patterns[2] = 8'b01010101;
    parity_patterns[3] = 8'b11001100;
    parity_patterns[4] = 8'b00111100;
    parity_patterns[5] = 8'b11110000;
    parity_patterns[6] = 8'b00001111;
    parity_patterns[7] = 8'b11111111;
  end

  // Lookup table for parity calculation
  reg [7:0] parity_lut [0:255];
  initial begin
    for (int i = 0; i < 256; i++) begin
      parity_lut[i] = ^{i[0], i[1], i[2], i[3], i[4], i[5], i[6], i[7]};
    end
  end

  // Optimized parity calculation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      parity_results <= 8'h00;
    end else if (header_valid) begin
      for (int i = 0; i < 8; i++) begin
        reg [7:0] masked_data;
        masked_data = header_data[7:0] & parity_patterns[i];
        parity_results[i] <= (i == 7) ? ~parity_lut[masked_data] : parity_lut[masked_data];
      end
    end
  end

endmodule

// ECC comparison module
module ecc_comparator (
  input wire clk,
  input wire reset_n,
  input wire [7:0] parity_results,
  input wire [7:0] ecc_in,
  input wire header_valid,
  output reg [7:0] ecc_calculated,
  output reg ecc_error
);

  // Lookup table for error detection
  reg [1:0] error_lut [0:255];
  initial begin
    for (int i = 0; i < 256; i++) begin
      error_lut[i] = (i == 0) ? 2'b00 : 2'b01;
    end
  end

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ecc_calculated <= 8'h00;
      ecc_error <= 1'b0;
    end else if (header_valid) begin
      ecc_calculated <= parity_results;
      ecc_error <= error_lut[parity_results ^ ecc_in][0];
    end
  end

endmodule