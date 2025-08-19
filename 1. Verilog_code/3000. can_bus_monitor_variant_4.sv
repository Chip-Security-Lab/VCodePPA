//SystemVerilog
module can_bus_monitor(
  input wire clk, rst_n,
  input wire can_rx, can_tx,
  input wire frame_valid, error_detected,
  input wire [10:0] rx_id,
  input wire [7:0] rx_data [0:7],
  input wire [3:0] rx_dlc,
  output reg [15:0] frames_received,
  output reg [15:0] errors_detected,
  output reg [15:0] bus_load_percent,
  output reg [7:0] last_error_type
);
  reg [31:0] total_bits, active_bits;
  reg prev_frame_valid, prev_error;
  wire [31:0] next_active_bits; 
  wire [15:0] next_frames_received;
  wire [15:0] next_errors_detected;
  wire [15:0] bus_load_calculation;
  
  // Carry-Lookahead adder for active_bits+1
  cla_adder32 active_bits_adder(
    .a(active_bits),
    .b(32'd1),
    .cin(1'b0),
    .sum(next_active_bits)
  );
  
  // Carry-Lookahead adder for frames_received+1
  cla_adder16 frames_adder(
    .a(frames_received),
    .b(16'd1),
    .cin(1'b0),
    .sum(next_frames_received)
  );
  
  // Carry-Lookahead adder for errors_detected+1
  cla_adder16 errors_adder(
    .a(errors_detected),
    .b(16'd1),
    .cin(1'b0),
    .sum(next_errors_detected)
  );
  
  // Bus load calculation using CLA multiplier and divider
  bus_load_calculator bus_load_calc(
    .active_bits(active_bits),
    .total_bits(total_bits),
    .bus_load(bus_load_calculation)
  );
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frames_received <= 0;
      errors_detected <= 0;
      bus_load_percent <= 0;
      last_error_type <= 0;
      total_bits <= 0;
      active_bits <= 0;
    end else begin
      prev_frame_valid <= frame_valid;
      prev_error <= error_detected;
      
      // Count frames and errors
      if (!prev_frame_valid && frame_valid)
        frames_received <= next_frames_received;
        
      if (!prev_error && error_detected) begin
        errors_detected <= next_errors_detected;
        // last_error_type would be set based on error flags
      end
      
      // Calculate bus load
      total_bits <= total_bits + 1;
      if (!can_rx) active_bits <= next_active_bits;
      
      if (total_bits >= 32'd1000) begin
        bus_load_percent <= bus_load_calculation;
        total_bits <= 0;
        active_bits <= 0;
      end
    end
  end
endmodule

module cla_adder32(
  input wire [31:0] a,
  input wire [31:0] b,
  input wire cin,
  output wire [31:0] sum
);
  wire [31:0] p, g;  // Propagate and generate signals
  wire [8:0] c;      // Carry signals with extra bit for carry-in
  
  // Generate propagate and generate signals
  assign p = a ^ b;
  assign g = a & b;
  
  // Carry assignment
  assign c[0] = cin;
  
  // First level of 4-bit CLA blocks
  assign c[1] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
  assign c[2] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & c[1]);
  assign c[3] = g[11] | (p[11] & g[10]) | (p[11] & p[10] & g[9]) | (p[11] & p[10] & p[9] & g[8]) | (p[11] & p[10] & p[9] & p[8] & c[2]);
  assign c[4] = g[15] | (p[15] & g[14]) | (p[15] & p[14] & g[13]) | (p[15] & p[14] & p[13] & g[12]) | (p[15] & p[14] & p[13] & p[12] & c[3]);
  assign c[5] = g[19] | (p[19] & g[18]) | (p[19] & p[18] & g[17]) | (p[19] & p[18] & p[17] & g[16]) | (p[19] & p[18] & p[17] & p[16] & c[4]);
  assign c[6] = g[23] | (p[23] & g[22]) | (p[23] & p[22] & g[21]) | (p[23] & p[22] & p[21] & g[20]) | (p[23] & p[22] & p[21] & p[20] & c[5]);
  assign c[7] = g[27] | (p[27] & g[26]) | (p[27] & p[26] & g[25]) | (p[27] & p[26] & p[25] & g[24]) | (p[27] & p[26] & p[25] & p[24] & c[6]);
  assign c[8] = g[31] | (p[31] & g[30]) | (p[31] & p[30] & g[29]) | (p[31] & p[30] & p[29] & g[28]) | (p[31] & p[30] & p[29] & p[28] & c[7]);
  
  // Generate internal carries for each 4-bit block
  wire [31:0] internal_c;
  
  // Block 0 (bits 0-3)
  assign internal_c[0] = c[0];
  assign internal_c[1] = g[0] | (p[0] & c[0]);
  assign internal_c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
  assign internal_c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  
  // Block 1 (bits 4-7)
  assign internal_c[4] = c[1];
  assign internal_c[5] = g[4] | (p[4] & c[1]);
  assign internal_c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & c[1]);
  assign internal_c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & c[1]);
  
  // Block 2 (bits 8-11)
  assign internal_c[8] = c[2];
  assign internal_c[9] = g[8] | (p[8] & c[2]);
  assign internal_c[10] = g[9] | (p[9] & g[8]) | (p[9] & p[8] & c[2]);
  assign internal_c[11] = g[10] | (p[10] & g[9]) | (p[10] & p[9] & g[8]) | (p[10] & p[9] & p[8] & c[2]);
  
  // Block 3 (bits 12-15)
  assign internal_c[12] = c[3];
  assign internal_c[13] = g[12] | (p[12] & c[3]);
  assign internal_c[14] = g[13] | (p[13] & g[12]) | (p[13] & p[12] & c[3]);
  assign internal_c[15] = g[14] | (p[14] & g[13]) | (p[14] & p[13] & g[12]) | (p[14] & p[13] & p[12] & c[3]);
  
  // Block 4 (bits 16-19)
  assign internal_c[16] = c[4];
  assign internal_c[17] = g[16] | (p[16] & c[4]);
  assign internal_c[18] = g[17] | (p[17] & g[16]) | (p[17] & p[16] & c[4]);
  assign internal_c[19] = g[18] | (p[18] & g[17]) | (p[18] & p[17] & g[16]) | (p[18] & p[17] & p[16] & c[4]);
  
  // Block 5 (bits 20-23)
  assign internal_c[20] = c[5];
  assign internal_c[21] = g[20] | (p[20] & c[5]);
  assign internal_c[22] = g[21] | (p[21] & g[20]) | (p[21] & p[20] & c[5]);
  assign internal_c[23] = g[22] | (p[22] & g[21]) | (p[22] & p[21] & g[20]) | (p[22] & p[21] & p[20] & c[5]);
  
  // Block 6 (bits 24-27)
  assign internal_c[24] = c[6];
  assign internal_c[25] = g[24] | (p[24] & c[6]);
  assign internal_c[26] = g[25] | (p[25] & g[24]) | (p[25] & p[24] & c[6]);
  assign internal_c[27] = g[26] | (p[26] & g[25]) | (p[26] & p[25] & g[24]) | (p[26] & p[25] & p[24] & c[6]);
  
  // Block 7 (bits 28-31)
  assign internal_c[28] = c[7];
  assign internal_c[29] = g[28] | (p[28] & c[7]);
  assign internal_c[30] = g[29] | (p[29] & g[28]) | (p[29] & p[28] & c[7]);
  assign internal_c[31] = g[30] | (p[30] & g[29]) | (p[30] & p[29] & g[28]) | (p[30] & p[29] & p[28] & c[7]);
  
  // Calculate sum
  assign sum = p ^ internal_c;
endmodule

module cla_adder16(
  input wire [15:0] a,
  input wire [15:0] b,
  input wire cin,
  output wire [15:0] sum
);
  wire [15:0] p, g;  // Propagate and generate signals
  wire [4:0] c;      // Carry signals with extra bit for carry-in
  
  // Generate propagate and generate signals
  assign p = a ^ b;
  assign g = a & b;
  
  // Carry assignment
  assign c[0] = cin;
  
  // First level of 4-bit CLA blocks
  assign c[1] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
  assign c[2] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & c[1]);
  assign c[3] = g[11] | (p[11] & g[10]) | (p[11] & p[10] & g[9]) | (p[11] & p[10] & p[9] & g[8]) | (p[11] & p[10] & p[9] & p[8] & c[2]);
  assign c[4] = g[15] | (p[15] & g[14]) | (p[15] & p[14] & g[13]) | (p[15] & p[14] & p[13] & g[12]) | (p[15] & p[14] & p[13] & p[12] & c[3]);
  
  // Generate internal carries for each 4-bit block
  wire [15:0] internal_c;
  
  // Block 0 (bits 0-3)
  assign internal_c[0] = c[0];
  assign internal_c[1] = g[0] | (p[0] & c[0]);
  assign internal_c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
  assign internal_c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  
  // Block 1 (bits 4-7)
  assign internal_c[4] = c[1];
  assign internal_c[5] = g[4] | (p[4] & c[1]);
  assign internal_c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & c[1]);
  assign internal_c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & c[1]);
  
  // Block 2 (bits 8-11)
  assign internal_c[8] = c[2];
  assign internal_c[9] = g[8] | (p[8] & c[2]);
  assign internal_c[10] = g[9] | (p[9] & g[8]) | (p[9] & p[8] & c[2]);
  assign internal_c[11] = g[10] | (p[10] & g[9]) | (p[10] & p[9] & g[8]) | (p[10] & p[9] & p[8] & c[2]);
  
  // Block 3 (bits 12-15)
  assign internal_c[12] = c[3];
  assign internal_c[13] = g[12] | (p[12] & c[3]);
  assign internal_c[14] = g[13] | (p[13] & g[12]) | (p[13] & p[12] & c[3]);
  assign internal_c[15] = g[14] | (p[14] & g[13]) | (p[14] & p[13] & g[12]) | (p[14] & p[13] & p[12] & c[3]);
  
  // Calculate sum
  assign sum = p ^ internal_c;
endmodule

module bus_load_calculator(
  input wire [31:0] active_bits,
  input wire [31:0] total_bits,
  output wire [15:0] bus_load
);
  wire [31:0] active_bits_x_100;
  
  // Multiply active_bits by 100 using shifts and adds
  // 100 = 64 + 32 + 4
  wire [31:0] active_bits_x_64 = {active_bits[25:0], 6'b0};
  wire [31:0] active_bits_x_32 = {active_bits[26:0], 5'b0};
  wire [31:0] active_bits_x_4 = {active_bits[29:0], 2'b0};
  
  wire [31:0] sum1, sum2;
  
  cla_adder32 mult_adder1(
    .a(active_bits_x_64),
    .b(active_bits_x_32),
    .cin(1'b0),
    .sum(sum1)
  );
  
  cla_adder32 mult_adder2(
    .a(sum1),
    .b(active_bits_x_4),
    .cin(1'b0),
    .sum(active_bits_x_100)
  );
  
  // Division approximation using reciprocal multiplication
  // For simplicity, we'll use a fixed-point approach
  // since total_bits is bounded to 1000, we can use direct division
  
  // Placeholder for actual fixed-point division
  // In a real implementation, you'd use a more sophisticated divider
  assign bus_load = (active_bits_x_100 / total_bits) & 16'hFFFF;
endmodule