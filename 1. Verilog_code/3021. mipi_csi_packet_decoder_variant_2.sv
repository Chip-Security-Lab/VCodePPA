//SystemVerilog
module mipi_csi_packet_decoder (
  input wire clk, rst_n,
  input wire [31:0] packet_data,
  input wire packet_req, // Valid signal converted to Request signal
  output reg [7:0] packet_type,
  output reg [15:0] word_count,
  output reg [7:0] virtual_channel,
  output reg is_long_packet,
  output reg decode_error,
  output reg packet_ack // Ready signal converted to Acknowledge signal
);

  // Registered inputs to break critical path and buffer high-fanout signals
  reg [31:0] packet_data_r;
  reg packet_req_r;

  // Register inputs on clock edge
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      packet_data_r <= 32'b0;
      packet_req_r <= 1'b0;
    end else begin
      // Register inputs unconditionally
      packet_data_r <= packet_data;
      packet_req_r <= packet_req;
    end
  end

  // Logic now operates on registered inputs in the next cycle
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      packet_type <= 8'h00;
      word_count <= 16'h0000;
      virtual_channel <= 8'h00;
      is_long_packet <= 1'b0;
      decode_error <= 1'b0;
      packet_ack <= 1'b0;
    end else begin
      // Process data when registered request is asserted
      if (packet_req_r) begin
        // Outputs are based on registered inputs
        packet_type <= packet_data_r[7:0];
        virtual_channel <= packet_data_r[15:8] & 8'h03;
        word_count <= packet_data_r[31:16];

        // Comparison logic for flags based on registered byte packet_data_r[7:0]
        // This registered signal now drives the comparison logic, reducing fanout from the input pin
        if (packet_data_r[7:0] == 8'h00) begin
          decode_error <= 1'b1;
          is_long_packet <= 1'b0;
        end else if (packet_data_r[7:0] > 8'h0F) begin
          decode_error <= 1'b0;
          is_long_packet <= 1'b1;
        end else begin
          decode_error <= 1'b0;
          is_long_packet <= 1'b0;
        end

        // Assert acknowledge in the same cycle as processing, relative to registered request
        // This introduces one cycle latency in the Req-Ack handshake
        packet_ack <= 1'b1;
      end else begin
        // Deassert acknowledge when registered request is low
        packet_ack <= 1'b0;
        // Other outputs retain their value when packet_req_r is low,
        // matching the behavior of the original code when packet_req is low.
      end
    end
  end

endmodule