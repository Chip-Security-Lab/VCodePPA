//SystemVerilog
module mipi_csi_packet_decoder (
  input wire clk, rst_n,
  input wire [31:0] packet_data,
  input wire packet_valid,
  output reg [7:0] packet_type,
  output reg [15:0] word_count,
  output reg [7:0] virtual_channel,
  output reg is_long_packet,
  output reg decode_error
);

  // Buffered inputs to reduce fanout and create pipeline stage 1
  logic [31:0] packet_data_reg;
  logic packet_valid_reg;

  // Internal signals for next state calculation (outputs of combinatorial logic)
  // These signals are driven by the registered inputs
  logic [7:0] comb_packet_type;
  logic [7:0] comb_virtual_channel;
  logic [15:0] comb_word_count;
  logic comb_is_long_packet;
  logic comb_decode_error;

  // Stage 1: Register inputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      packet_data_reg <= 32'h0;
      packet_valid_reg <= 1'b0;
    end else begin
      packet_data_reg <= packet_data;
      packet_valid_reg <= packet_valid;
    end
  end

  // Combinational logic to calculate the next values based on REGISTERED inputs
  // This forms pipeline stage 2 (combinational part)
  always_comb begin
    // Extract data fields directly from registered data
    comb_packet_type = packet_data_reg[7:0];
    comb_virtual_channel = packet_data_reg[15:8] & 8'h03; // Mask to keep only bits 9:8 for VC
    comb_word_count = packet_data_reg[31:16];

    // Initialize flags
    comb_is_long_packet = 1'b0;
    comb_decode_error = 1'b0;

    // Determine flags based on packet type using a prioritized structure
    // Check for decode error (Reserved packet type 0)
    if (comb_packet_type == 8'h00) begin
      comb_decode_error = 1'b1;
    end
    // Check for long packet (Packet types 16-255)
    // This condition is mutually exclusive with the decode_error condition (type 0)
    else if (comb_packet_type > 8'h0F) begin // Equivalent to >= 8'h10
      comb_is_long_packet = 1'b1;
    end
    // For packet types 1-15 (short packets), both flags remain 0 (default initialized)
  end

  // Stage 2: Register outputs (final stage)
  // Update registers with the calculated next values based on REGISTERED packet_valid
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset values
      packet_type <= 8'h00;
      word_count <= 16'h0000;
      virtual_channel <= 8'h00;
      is_long_packet <= 1'b0;
      decode_error <= 1'b0;
    end else if (packet_valid_reg) begin // Use registered packet_valid
      // Update registers with the calculated next values
      packet_type <= comb_packet_type;
      virtual_channel <= comb_virtual_channel;
      word_count <= comb_word_count;
      is_long_packet <= comb_is_long_packet;
      decode_error <= comb_decode_error;
    end
    // If packet_valid_reg is low, registers hold their current value (implicit behavior)
  end

endmodule