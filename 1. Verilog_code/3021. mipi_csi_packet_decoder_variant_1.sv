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
  // state variable is unused in the provided logic, and removed

  // Internal registers for input buffering and pipelining
  // These registers buffer the high-fanout input 'packet_data' and its validity signal
  reg packet_valid_r;
  reg [31:0] packet_data_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all registers
      packet_valid_r <= 1'b0;
      packet_data_r <= 32'h0;
      packet_type <= 8'h00;
      word_count <= 16'h0000;
      virtual_channel <= 8'h00;
      is_long_packet <= 1'b0;
      decode_error <= 1'b0;
    end else begin
      // Stage 1: Register inputs
      // This breaks the combinational path from input pins to the decoding logic.
      // packet_data is buffered into packet_data_r, reducing packet_data's fanout.
      packet_valid_r <= packet_valid;
      packet_data_r <= packet_data;

      // Stage 2: Decode and register outputs based on registered inputs
      // The combinational logic now operates on packet_data_r.
      // Outputs are registered, enabled by the registered valid signal.
      if (packet_valid_r) begin
        // Decode fields
        packet_type <= packet_data_r[7:0];
        virtual_channel <= packet_data_r[15:8] & 8'h03;
        word_count <= packet_data_r[31:16];

        // Optimized comparison logic
        // packet_data_r[7:0] > 8'h0F is equivalent to packet_data_r[7:4] != 4'b0000
        is_long_packet <= (packet_data_r[7] | packet_data_r[6] | packet_data_r[5] | packet_data_r[4]);

        // packet_data_r[7:0] == 8'h00 is equivalent to !(packet_data_r[7:0] == 8'b00000000)
        decode_error <= !(packet_data_r[7] | packet_data_r[6] | packet_data_r[5] | packet_data_r[4] | packet_data_r[3] | packet_data_r[2] | packet_data_r[1] | packet_data_r[0]);

      end
      // Outputs hold their value when packet_valid_r is low.
    end
  end

endmodule