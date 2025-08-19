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

  reg [3:0] state;
  reg [7:0] packet_id, last_packet_id;
  reg [15:0] payload_length, bytes_received;
  wire [15:0] next_bytes_received;
  wire [3:0] next_state;
  wire [31:0] next_decoded_data;
  wire [3:0] next_decoded_type;
  wire next_decode_valid;
  wire next_protocol_error;

  // Combinational logic for next state
  assign next_bytes_received = bytes_received + 16'd4;
  
  // Protocol type decoder
  wire is_csi = (protocol_type == 4'd0);
  wire is_dsi = (protocol_type == 4'd1);
  wire is_i3c = (protocol_type == 4'd2);
  wire is_rffe = (protocol_type == 4'd3);
  wire is_valid_protocol = is_csi | is_dsi | is_i3c | is_rffe;

  // State machine logic using explicit multiplexer structure
  reg [3:0] state_mux_out;
  always @(*) begin
    state_mux_out = state; // Default value
    
    if (!reset_n) begin
      state_mux_out = 4'd0;
    end else if (valid_in) begin
      if (!is_valid_protocol) begin
        state_mux_out = 4'd0;
      end else if (is_i3c || is_rffe) begin
        state_mux_out = 4'd0;
      end else if (state == 4'd0) begin
        state_mux_out = 4'd1;
      end else if (next_bytes_received >= payload_length) begin
        state_mux_out = 4'd0;
      end
    end
  end
  assign next_state = state_mux_out;

  // Decoded data logic using explicit multiplexer structure
  reg [31:0] decoded_data_mux_out;
  always @(*) begin
    decoded_data_mux_out = decoded_data; // Default value
    
    if (!reset_n) begin
      decoded_data_mux_out = 32'h0;
    end else if (valid_in) begin
      decoded_data_mux_out = data_in;
    end
  end
  assign next_decoded_data = decoded_data_mux_out;

  // Decoded type logic using explicit multiplexer structure
  reg [3:0] decoded_type_mux_out;
  always @(*) begin
    decoded_type_mux_out = decoded_type; // Default value
    
    if (!reset_n) begin
      decoded_type_mux_out = 4'h0;
    end else if (valid_in) begin
      if (is_csi) begin
        decoded_type_mux_out = {3'b000, (data_in[31:24] == 8'hFF)};
      end else if (is_dsi) begin
        decoded_type_mux_out = {2'b01, data_in[31:30]};
      end else if (is_i3c) begin
        decoded_type_mux_out = {2'b10, data_in[1:0]};
      end else if (is_rffe) begin
        decoded_type_mux_out = {2'b11, data_in[1:0]};
      end
    end
  end
  assign next_decoded_type = decoded_type_mux_out;

  // Decode valid logic using explicit multiplexer structure
  reg decode_valid_mux_out;
  always @(*) begin
    decode_valid_mux_out = 1'b0; // Default value
    
    if (!reset_n) begin
      decode_valid_mux_out = 1'b0;
    end else if (valid_in) begin
      if (!is_valid_protocol) begin
        decode_valid_mux_out = 1'b0;
      end else if (is_csi || is_dsi) begin
        decode_valid_mux_out = (state != 4'd0);
      end else begin
        decode_valid_mux_out = 1'b1;
      end
    end
  end
  assign next_decode_valid = decode_valid_mux_out;

  // Protocol error logic using explicit multiplexer structure
  reg protocol_error_mux_out;
  always @(*) begin
    protocol_error_mux_out = protocol_error; // Default value
    
    if (!reset_n) begin
      protocol_error_mux_out = 1'b0;
    end else if (valid_in) begin
      protocol_error_mux_out = !is_valid_protocol;
    end
  end
  assign next_protocol_error = protocol_error_mux_out;

  // Sequential logic
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
      state <= next_state;
      protocol_error <= next_protocol_error;
      decode_valid <= next_decode_valid;
      decoded_data <= next_decoded_data;
      decoded_type <= next_decoded_type;
      
      if (state == 4'd0) begin
        packet_id <= data_in[7:0];
        payload_length <= is_dsi ? {8'h0, data_in[15:8]} * 2 : data_in[23:8];
        bytes_received <= 16'd0;
      end else begin
        bytes_received <= next_bytes_received;
      end
    end else begin
      decode_valid <= 1'b0;
    end
  end

endmodule