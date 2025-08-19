//SystemVerilog
module mipi_protocol_analyzer (
  input wire clk, reset_n,
  input wire [31:0] data_in,
  input wire valid_in,
  input wire [3:0] protocol_type,
  output reg [31:0] decoded_data,
  output reg [3:0] decoded_type,
  output reg protocol_error,
  output reg decode_valid
);

  // Stage 1 Registers
  reg [31:0] data_stage1;
  reg [3:0] protocol_type_stage1;
  reg valid_stage1;
  reg [3:0] state_stage1;
  reg [7:0] packet_id_stage1;
  reg [15:0] payload_length_stage1;
  reg [15:0] bytes_received_stage1;

  // Stage 2 Registers
  reg [31:0] data_stage2;
  reg [3:0] protocol_type_stage2;
  reg valid_stage2;
  reg [3:0] state_stage2;
  reg [7:0] packet_id_stage2;
  reg [15:0] payload_length_stage2;
  reg [15:0] bytes_received_stage2;
  reg [31:0] decoded_data_stage2;
  reg [3:0] decoded_type_stage2;
  reg protocol_error_stage2;
  reg decode_valid_stage2;

  // Reset logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage1 <= 4'd0;
      state_stage2 <= 4'd0;
      protocol_error <= 1'b0;
      decode_valid <= 1'b0;
      bytes_received_stage1 <= 16'd0;
      bytes_received_stage2 <= 16'd0;
      packet_id_stage1 <= 8'h0;
      packet_id_stage2 <= 8'h0;
      payload_length_stage1 <= 16'h0;
      payload_length_stage2 <= 16'h0;
      decoded_data <= 32'h0;
      decoded_type <= 4'h0;
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
    end
  end

  // Stage 1: Input and State Processing
  always @(posedge clk) begin
    if (reset_n) begin
      data_stage1 <= data_in;
      protocol_type_stage1 <= protocol_type;
      valid_stage1 <= valid_in;
      state_stage1 <= state_stage2;
      packet_id_stage1 <= packet_id_stage2;
      payload_length_stage1 <= payload_length_stage2;
      bytes_received_stage1 <= bytes_received_stage2;
    end
  end

  // Stage 2: Protocol Processing
  always @(posedge clk) begin
    if (reset_n) begin
      data_stage2 <= data_stage1;
      protocol_type_stage2 <= protocol_type_stage1;
      valid_stage2 <= valid_stage1;
      state_stage2 <= state_stage1;
      packet_id_stage2 <= packet_id_stage1;
      payload_length_stage2 <= payload_length_stage1;
      bytes_received_stage2 <= bytes_received_stage1;

      if (valid_stage1) begin
        case (protocol_type_stage1)
          4'd0: begin // CSI Protocol
            if (state_stage1 == 4'd0) begin
              packet_id_stage2 <= data_stage1[7:0];
              payload_length_stage2 <= data_stage1[23:8];
              bytes_received_stage2 <= 16'd0;
              state_stage2 <= 4'd1;
              decode_valid_stage2 <= 1'b0;
            end else begin
              bytes_received_stage2 <= bytes_received_stage1 + 4;
              decoded_data_stage2 <= data_stage1;
              decoded_type_stage2 <= {3'b000, (data_stage1[31:24] == 8'hFF) ? 1'b1 : 1'b0};
              decode_valid_stage2 <= 1'b1;
              if (bytes_received_stage1 + 4 >= payload_length_stage1) state_stage2 <= 4'd0;
            end
          end
          4'd1: begin // DSI Protocol
            if (state_stage1 == 4'd0) begin
              packet_id_stage2 <= data_stage1[7:0];
              payload_length_stage2 <= data_stage1[15:8] * 2;
              bytes_received_stage2 <= 16'd0;
              state_stage2 <= 4'd1;
              decode_valid_stage2 <= 1'b0;
            end else begin
              bytes_received_stage2 <= bytes_received_stage1 + 4;
              decoded_data_stage2 <= data_stage1;
              decoded_type_stage2 <= {2'b01, data_stage1[31:30]};
              decode_valid_stage2 <= 1'b1;
              if (bytes_received_stage1 + 4 >= payload_length_stage1) state_stage2 <= 4'd0;
            end
          end
          4'd2: begin // I3C Protocol
            decoded_data_stage2 <= data_stage1;
            decoded_type_stage2 <= {2'b10, data_stage1[1:0]};
            decode_valid_stage2 <= 1'b1;
            state_stage2 <= 4'd0;
          end
          4'd3: begin // RFFE Protocol
            decoded_data_stage2 <= data_stage1;
            decoded_type_stage2 <= {2'b11, data_stage1[1:0]};
            decode_valid_stage2 <= 1'b1;
            state_stage2 <= 4'd0;
          end
          default: begin // Error Handler
            protocol_error_stage2 <= 1'b1;
            state_stage2 <= 4'd0;
            decode_valid_stage2 <= 1'b0;
          end
        endcase
      end else begin
        decode_valid_stage2 <= 1'b0;
      end
    end
  end

  // Output Stage
  always @(posedge clk) begin
    if (reset_n) begin
      decoded_data <= decoded_data_stage2;
      decoded_type <= decoded_type_stage2;
      protocol_error <= protocol_error_stage2;
      decode_valid <= decode_valid_stage2;
    end
  end

endmodule