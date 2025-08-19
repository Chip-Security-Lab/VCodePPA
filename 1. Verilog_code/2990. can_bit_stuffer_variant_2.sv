//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: can_bit_stuffer_top.v
// Author: Restructured Design
// Description: Top level module for CAN bit stuffing operation
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module can_bit_stuffer(
  input wire clk,
  input wire rst_n,
  input wire data_in,
  input wire data_valid,
  input wire stuffing_active,
  output wire data_out,
  output wire data_out_valid,
  output wire stuff_error
);

  // Internal signals
  wire [2:0] bit_counter;
  wire bit_is_same;
  wire stuff_needed;
  wire last_bit_val;

  // Bit sequence monitor - tracks consecutive identical bits
  can_bit_monitor bit_monitor_inst (
    .clk             (clk),
    .rst_n           (rst_n),
    .data_in         (data_in),
    .data_valid      (data_valid),
    .stuffing_active (stuffing_active),
    .bit_counter     (bit_counter),
    .bit_is_same     (bit_is_same),
    .last_bit        (last_bit_val)
  );

  // Stuff bit controller - determines when to insert stuff bits
  can_stuff_controller stuff_controller_inst (
    .clk             (clk),
    .rst_n           (rst_n),
    .data_in         (data_in),
    .data_valid      (data_valid),
    .stuffing_active (stuffing_active),
    .bit_counter     (bit_counter),
    .bit_is_same     (bit_is_same),
    .last_bit        (last_bit_val),
    .stuff_needed    (stuff_needed),
    .data_out        (data_out),
    .data_out_valid  (data_out_valid),
    .stuff_error     (stuff_error)
  );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: can_bit_monitor.v
// Author: Restructured Design
// Description: Monitors consecutive identical bits in the CAN bit stream
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module can_bit_monitor (
  input wire clk,
  input wire rst_n,
  input wire data_in,
  input wire data_valid,
  input wire stuffing_active,
  output reg [2:0] bit_counter,
  output wire bit_is_same,
  output reg last_bit
);

  // Pre-compute if current bit matches the previous bit for faster comparison
  assign bit_is_same = (data_in == last_bit);

  // Optimized consecutive bit tracking
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter <= 3'b000;
      last_bit <= 1'b0;
    end else if (data_valid && stuffing_active) begin
      // Use efficient conditional increment/reset pattern
      bit_counter <= bit_is_same ? (bit_counter + 3'b001) : 3'b000;
      // Only update last_bit when bit changes (reducing toggle rate)
      if (!bit_is_same) begin
        last_bit <= data_in;
      end
    end
  end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: can_stuff_controller.v
// Author: Restructured Design
// Description: Controls bit stuffing insertion and output generation
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module can_stuff_controller (
  input wire clk,
  input wire rst_n,
  input wire data_in,
  input wire data_valid,
  input wire stuffing_active,
  input wire [2:0] bit_counter, 
  input wire bit_is_same,
  input wire last_bit,
  output wire stuff_needed,
  output reg data_out,
  output reg data_out_valid,
  output reg stuff_error
);

  reg stuff_in_progress;
  
  // Optimize comparison using equality check instead of range comparison
  assign stuff_needed = (bit_counter == 3'b100) && bit_is_same;
  
  // Output generation logic with improved state handling
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stuff_in_progress <= 1'b0;
      data_out <= 1'b1;
      data_out_valid <= 1'b0;
      stuff_error <= 1'b0;
    end else begin
      // Default state - only change when needed
      data_out_valid <= 1'b0;
      
      if (data_valid && stuffing_active) begin
        data_out_valid <= 1'b1; // Set valid for both normal and stuff bits
        
        if (stuff_needed && !stuff_in_progress) begin
          // Insert stuff bit (complement of last_bit)
          data_out <= ~last_bit;
          stuff_in_progress <= 1'b1;
        end else begin
          // Normal bit passing or reset after stuff bit
          data_out <= data_in;
          stuff_in_progress <= 1'b0;
        end
      end
    end
  end

endmodule