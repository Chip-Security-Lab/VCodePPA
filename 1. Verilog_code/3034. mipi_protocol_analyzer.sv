module mipi_protocol_analyzer (
  input wire clk, reset_n,
  input wire [31:0] data_in,
  input wire valid_in,
  input wire [3:0] protocol_type, // 0:CSI, 1:DSI, 2:I3C, 3:RFFE, etc.
  output reg [31:0] decoded_data,
  output reg [3:0] decoded_type,
  output reg protocol_error,
  output reg decode_valid
);
  reg [3:0] state;
  reg [7:0] packet_id, last_packet_id;
  reg [15:0] payload_length, bytes_received;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      protocol_error <= 1'b0;
      decode_valid <= 1'b0;
      bytes_received <= 16'd0;
      packet_id <= 8'h0;
      last_packet_id <= 8'h0;
      payload_length <= 16'h0;
      decoded_data <= 32'h0;
      decoded_type <= 4'h0;
    end else if (valid_in) begin
      case (protocol_type)
        4'd0: begin // CSI protocol
          if (state == 4'd0) begin // Header
            packet_id <= data_in[7:0];
            payload_length <= data_in[23:8];
            bytes_received <= 16'd0;
            state <= 4'd1;
            decode_valid <= 1'b0;
          end else begin // Payload
            bytes_received <= bytes_received + 4;
            decoded_data <= data_in;
            decoded_type <= {3'b000, (data_in[31:24] == 8'hFF) ? 1'b1 : 1'b0};
            decode_valid <= 1'b1;
            if (bytes_received + 4 >= payload_length) state <= 4'd0;
          end
        end
        
        4'd1: begin // DSI protocol
          if (state == 4'd0) begin
            packet_id <= data_in[7:0];
            payload_length <= data_in[15:8] * 2; // DSI uses words
            bytes_received <= 16'd0;
            state <= 4'd1;
            decode_valid <= 1'b0;
          end else begin
            bytes_received <= bytes_received + 4;
            decoded_data <= data_in;
            decoded_type <= {2'b01, data_in[31:30]};
            decode_valid <= 1'b1;
            if (bytes_received + 4 >= payload_length) state <= 4'd0;
          end
        end
        
        4'd2: begin // I3C protocol
          decoded_data <= data_in;
          decoded_type <= {2'b10, data_in[1:0]};
          decode_valid <= 1'b1;
          state <= 4'd0; // Single packet protocol
        end
        
        4'd3: begin // RFFE protocol
          decoded_data <= data_in;
          decoded_type <= {2'b11, data_in[1:0]};
          decode_valid <= 1'b1;
          state <= 4'd0; // Single packet protocol
        end
        
        default: begin
          protocol_error <= 1'b1;
          state <= 4'd0;
          decode_valid <= 1'b0;
        end
      endcase
    end else begin
      decode_valid <= 1'b0;
    end
  end
endmodule