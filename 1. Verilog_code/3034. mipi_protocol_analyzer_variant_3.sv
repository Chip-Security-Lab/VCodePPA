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

  reg [3:0] state, next_state;
  reg [7:0] packet_id, last_packet_id;
  reg [15:0] payload_length, bytes_received;
  
  reg [31:0] data_in_buf;
  reg [15:0] bytes_received_buf;
  reg [7:0] d0_buf;
  reg [7:0] b0_buf;
  reg [7:0] h0_buf;
  
  reg [31:0] data_in_pipe;
  reg [15:0] bytes_received_pipe;
  reg [3:0] protocol_type_pipe;
  reg valid_in_pipe;
  reg [3:0] state_pipe;
  reg [15:0] payload_length_pipe;
  reg [7:0] packet_id_pipe;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_in_buf <= 32'd0;
      bytes_received_buf <= 16'd0;
      d0_buf <= 8'd0;
      b0_buf <= 8'd0;
      h0_buf <= 8'd0;
      data_in_pipe <= 32'd0;
      bytes_received_pipe <= 16'd0;
      protocol_type_pipe <= 4'd0;
      valid_in_pipe <= 1'b0;
      state_pipe <= 4'd0;
      payload_length_pipe <= 16'd0;
      packet_id_pipe <= 8'd0;
    end else begin
      data_in_buf <= data_in;
      bytes_received_buf <= bytes_received;
      d0_buf <= data_in[7:0];
      b0_buf <= data_in[15:8];
      h0_buf <= data_in[23:16];
      data_in_pipe <= data_in_buf;
      bytes_received_pipe <= bytes_received_buf;
      protocol_type_pipe <= protocol_type;
      valid_in_pipe <= valid_in;
      state_pipe <= state;
      payload_length_pipe <= payload_length;
      packet_id_pipe <= packet_id;
    end
  end

  always @(*) begin
    next_state = state;
    if (valid_in_pipe) begin
      if (protocol_type_pipe == 4'd0 || protocol_type_pipe == 4'd1) begin
        if (state_pipe == 4'd0) begin
          next_state = 4'd1;
        end else if (bytes_received_pipe + 4 >= payload_length_pipe) begin
          next_state = 4'd0;
        end
      end else if (protocol_type_pipe == 4'd2 || protocol_type_pipe == 4'd3) begin
        next_state = 4'd0;
      end else begin
        next_state = 4'd0;
      end
    end
  end

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
    end else begin
      state <= next_state;
      
      if (valid_in_pipe) begin
        if (protocol_type_pipe == 4'd0) begin
          if (state_pipe == 4'd0) begin
            packet_id <= d0_buf;
            payload_length <= {h0_buf, b0_buf};
            bytes_received <= 16'd0;
            decode_valid <= 1'b0;
          end else begin
            bytes_received <= bytes_received_pipe + 4;
            decoded_data <= data_in_pipe;
            decoded_type <= {3'b000, (data_in_pipe[31:24] == 8'hFF) ? 1'b1 : 1'b0};
            decode_valid <= 1'b1;
          end
        end else if (protocol_type_pipe == 4'd1) begin
          if (state_pipe == 4'd0) begin
            packet_id <= d0_buf;
            payload_length <= b0_buf * 2;
            bytes_received <= 16'd0;
            decode_valid <= 1'b0;
          end else begin
            bytes_received <= bytes_received_pipe + 4;
            decoded_data <= data_in_pipe;
            decoded_type <= {2'b01, data_in_pipe[31:30]};
            decode_valid <= 1'b1;
          end
        end else if (protocol_type_pipe == 4'd2) begin
          decoded_data <= data_in_pipe;
          decoded_type <= {2'b10, data_in_pipe[1:0]};
          decode_valid <= 1'b1;
        end else if (protocol_type_pipe == 4'd3) begin
          decoded_data <= data_in_pipe;
          decoded_type <= {2'b11, data_in_pipe[1:0]};
          decode_valid <= 1'b1;
        end else begin
          protocol_error <= 1'b1;
          decode_valid <= 1'b0;
        end
      end else begin
        decode_valid <= 1'b0;
      end
    end
  end
endmodule