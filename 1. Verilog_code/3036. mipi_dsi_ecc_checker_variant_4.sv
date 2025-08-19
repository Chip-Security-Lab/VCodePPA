//SystemVerilog
// ECC Parity Calculator Module - Optimized
module ecc_parity_calculator (
  input wire [23:0] data,
  input wire [7:0] parity_bits,
  output wire parity_out
);
  // Pre-compute parity groups to reduce critical path
  wire [5:0] group_parity;
  
  // Split data into 4-bit groups for parallel processing
  assign group_parity[0] = (parity_bits[0] ? data[0] : 0) ^ 
                          (parity_bits[1] ? data[1] : 0) ^ 
                          (parity_bits[2] ? data[2] : 0) ^ 
                          (parity_bits[3] ? data[3] : 0);
                          
  assign group_parity[1] = (parity_bits[4] ? data[4] : 0) ^ 
                          (parity_bits[5] ? data[5] : 0) ^ 
                          (parity_bits[6] ? data[6] : 0) ^ 
                          (parity_bits[7] ? data[7] : 0);
                          
  assign group_parity[2] = (parity_bits[0] ? data[8] : 0) ^ 
                          (parity_bits[1] ? data[9] : 0) ^ 
                          (parity_bits[2] ? data[10] : 0) ^ 
                          (parity_bits[3] ? data[11] : 0);
                          
  assign group_parity[3] = (parity_bits[4] ? data[12] : 0) ^ 
                          (parity_bits[5] ? data[13] : 0) ^ 
                          (parity_bits[6] ? data[14] : 0) ^ 
                          (parity_bits[7] ? data[15] : 0);
                          
  assign group_parity[4] = (parity_bits[0] ? data[16] : 0) ^ 
                          (parity_bits[1] ? data[17] : 0) ^ 
                          (parity_bits[2] ? data[18] : 0) ^ 
                          (parity_bits[3] ? data[19] : 0);
                          
  assign group_parity[5] = (parity_bits[4] ? data[20] : 0) ^ 
                          (parity_bits[5] ? data[21] : 0) ^ 
                          (parity_bits[6] ? data[22] : 0) ^ 
                          (parity_bits[7] ? data[23] : 0);
  
  // Combine group parities with balanced tree structure
  assign parity_out = group_parity[0] ^ group_parity[1] ^ 
                     group_parity[2] ^ group_parity[3] ^ 
                     group_parity[4] ^ group_parity[5];
endmodule

// ECC Generator Module - Optimized
module ecc_generator (
  input wire clk,
  input wire reset_n,
  input wire [23:0] header_data,
  input wire header_valid,
  output reg [7:0] ecc_calculated
);
  // Pre-compute all parity bits in parallel
  wire [7:0] parity_out;
  
  // Use optimized parity calculator instances
  ecc_parity_calculator parity_calc_0 (
    .data(header_data),
    .parity_bits(8'b10101010),
    .parity_out(parity_out[0])
  );
  
  ecc_parity_calculator parity_calc_1 (
    .data(header_data),
    .parity_bits(8'b01100110),
    .parity_out(parity_out[1])
  );
  
  ecc_parity_calculator parity_calc_2 (
    .data(header_data),
    .parity_bits(8'b01010101),
    .parity_out(parity_out[2])
  );
  
  ecc_parity_calculator parity_calc_3 (
    .data(header_data),
    .parity_bits(8'b11001100),
    .parity_out(parity_out[3])
  );
  
  ecc_parity_calculator parity_calc_4 (
    .data(header_data),
    .parity_bits(8'b00111100),
    .parity_out(parity_out[4])
  );
  
  ecc_parity_calculator parity_calc_5 (
    .data(header_data),
    .parity_bits(8'b11110000),
    .parity_out(parity_out[5])
  );
  
  ecc_parity_calculator parity_calc_6 (
    .data(header_data),
    .parity_bits(8'b00001111),
    .parity_out(parity_out[6])
  );
  
  ecc_parity_calculator parity_calc_7 (
    .data(header_data),
    .parity_bits(8'b11111111),
    .parity_out(parity_out[7])
  );
  
  // Register output with balanced timing
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      ecc_calculated <= 8'h00;
    else if (header_valid) begin
      ecc_calculated[6:0] <= parity_out[6:0];
      ecc_calculated[7] <= ~parity_out[7];
    end
  end
endmodule

// ECC Checker Module - Optimized
module ecc_checker (
  input wire clk,
  input wire reset_n,
  input wire [7:0] ecc_calculated,
  input wire [7:0] ecc_in,
  input wire header_valid,
  output reg ecc_error
);
  // Pre-compute error detection
  wire error_detected;
  assign error_detected = (ecc_calculated != ecc_in);
  
  // Register output with balanced timing
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      ecc_error <= 1'b0;
    else if (header_valid)
      ecc_error <= error_detected;
  end
endmodule

// Top-level MIPI DSI ECC Checker Module - Optimized
module mipi_dsi_ecc_checker (
  input wire clk,
  input wire reset_n,
  input wire [23:0] header_data,
  input wire [7:0] ecc_in,
  input wire header_valid,
  output wire ecc_error,
  output wire [7:0] ecc_calculated
);
  wire [7:0] internal_ecc;
  
  ecc_generator ecc_gen (
    .clk(clk),
    .reset_n(reset_n),
    .header_data(header_data),
    .header_valid(header_valid),
    .ecc_calculated(internal_ecc)
  );
  
  ecc_checker ecc_chk (
    .clk(clk),
    .reset_n(reset_n),
    .ecc_calculated(internal_ecc),
    .ecc_in(ecc_in),
    .header_valid(header_valid),
    .ecc_error(ecc_error)
  );
  
  assign ecc_calculated = internal_ecc;
endmodule