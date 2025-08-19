//SystemVerilog
module mipi_csi_packet_decoder (
  input wire clk,
  input wire rst_n,
  input wire [31:0] packet_data,
  input wire packet_valid,
  output logic [7:0] packet_type,
  output logic [15:0] word_count,
  output logic [7:0] virtual_channel,
  output logic is_long_packet,
  output logic decode_error
);

  // Internal pipeline registers Stage 1 (Input Registration)
  logic [31:0] packet_data_s1;
  logic packet_valid_s1;

  // Internal pipeline registers Stage 2 (Decoded Fields Registration)
  logic [7:0] packet_type_s2;
  logic [15:0] word_count_s2;
  logic [7:0] virtual_channel_s2;
  logic packet_valid_s2;

  // Internal pipeline registers Stage 3 (Comparison and Data Carry Registration)
  logic [7:0] packet_type_s3;
  logic [15:0] word_count_s3;
  logic [7:0] virtual_channel_s3;
  logic is_long_packet_s3;
  logic decode_error_s3;
  logic packet_valid_s3;

  // Combinatorial logic for Stage 2 (Decoding Fields)
  logic [7:0] packet_type_s2_combo;
  logic [15:0] word_count_s2_combo;
  logic [7:0] virtual_channel_s2_combo;

  assign packet_type_s2_combo = packet_data_s1[7:0];
  assign virtual_channel_s2_combo = packet_data_s1[15:8] & 8'h03;
  assign word_count_s2_combo = packet_data_s1[31:16];

  // Combinatorial logic for Stage 3 (Comparisons)
  logic is_long_packet_s3_combo;
  logic decode_error_s3_combo;

  assign is_long_packet_s3_combo = (packet_type_s2 > 8'h0F);
  assign decode_error_s3_combo = (packet_type_s2 == 8'h00);


  // Sequential logic for Stage 1 (Input Registration)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      packet_data_s1 <= 32'h0;
      packet_valid_s1 <= 1'b0;
    end else begin
      packet_data_s1 <= packet_data;
      packet_valid_s1 <= packet_valid;
    end
  end

  // Sequential logic for Stage 2 (Decode Fields Registration)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      packet_type_s2 <= 8'h00;
      word_count_s2 <= 16'h0000;
      virtual_channel_s2 <= 8'h00;
      packet_valid_s2 <= 1'b0;
    end else begin
      packet_type_s2 <= packet_type_s2_combo;
      word_count_s2 <= word_count_s2_combo;
      virtual_channel_s2 <= virtual_channel_s2_combo;
      packet_valid_s2 <= packet_valid_s1; // Propagate valid signal
    end
  end

  // Sequential logic for Stage 3 (Comparison and Data Carry Registration)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      packet_type_s3 <= 8'h00;
      word_count_s3 <= 16'h0000;
      virtual_channel_s3 <= 8'h00;
      is_long_packet_s3 <= 1'b0;
      decode_error_s3 <= 1'b0;
      packet_valid_s3 <= 1'b0;
    end else begin
      // Carry data from previous stage
      packet_type_s3 <= packet_type_s2;
      word_count_s3 <= word_count_s2;
      virtual_channel_s3 <= virtual_channel_s2;
      // Register comparison results
      is_long_packet_s3 <= is_long_packet_s3_combo;
      decode_error_s3 <= decode_error_s3_combo;
      // Propagate valid signal
      packet_valid_s3 <= packet_valid_s2;
    end
  end

  // Sequential logic for Output Registration (Conditional Update)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      packet_type <= 8'h00;
      word_count <= 16'h0000;
      virtual_channel <= 8'h00;
      is_long_packet <= 1'b0;
      decode_error <= 1'b0;
    end else if (packet_valid_s3) begin // Only update outputs when data is valid in the last stage
      packet_type <= packet_type_s3;
      word_count <= word_count_s3;
      virtual_channel <= virtual_channel_s3;
      is_long_packet <= is_long_packet_s3;
      decode_error <= decode_error_s3;
    end
    // If packet_valid_s3 is low, outputs hold their value, matching original behavior
  end

endmodule