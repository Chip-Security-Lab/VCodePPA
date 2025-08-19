//SystemVerilog
module mipi_protocol_analyzer (
  input wire clk,
  input wire reset_n,
  input wire [31:0] data_in,
  input wire valid_in,
  input wire [3:0] protocol_type,
  output wire [31:0] decoded_data,
  output wire [3:0] decoded_type,
  output wire protocol_error,
  output wire decode_valid
);

  // Buffered signals with single level
  reg [31:0] data_in_buf;
  reg valid_in_buf;
  reg [3:0] protocol_type_buf;
  
  // Single level buffer registers
  always @(posedge clk) begin
    data_in_buf <= data_in;
    valid_in_buf <= valid_in;
    protocol_type_buf <= protocol_type;
  end

  wire [7:0] packet_id;
  wire [15:0] payload_length;
  wire [15:0] bytes_received;
  wire [3:0] state;

  protocol_decoder decoder (
    .clk(clk),
    .reset_n(reset_n),
    .data_in(data_in_buf),
    .valid_in(valid_in_buf),
    .protocol_type(protocol_type_buf),
    .decoded_data(decoded_data),
    .decoded_type(decoded_type),
    .decode_valid(decode_valid)
  );

  packet_handler handler (
    .clk(clk),
    .reset_n(reset_n),
    .valid_in(valid_in_buf),
    .protocol_type(protocol_type_buf),
    .data_in(data_in_buf),
    .packet_id(packet_id),
    .payload_length(payload_length),
    .bytes_received(bytes_received),
    .state(state),
    .protocol_error(protocol_error)
  );
endmodule

module protocol_decoder (
  input wire clk,
  input wire reset_n,
  input wire [31:0] data_in,
  input wire valid_in,
  input wire [3:0] protocol_type,
  output reg [31:0] decoded_data,
  output reg [3:0] decoded_type,
  output reg decode_valid
);

  // Pre-compute protocol type checks
  wire is_csi = (protocol_type == 4'd0);
  wire is_dsi = (protocol_type == 4'd1);
  wire is_i3c = (protocol_type == 4'd2);
  wire is_rffe = (protocol_type == 4'd3);
  
  // Pre-compute decoded type bits
  wire csi_type_bit = (data_in[31:24] == 8'hFF);
  wire [1:0] dsi_type_bits = data_in[31:30];
  wire [1:0] i3c_rffe_type_bits = data_in[1:0];

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      decoded_data <= 32'h0;
      decoded_type <= 4'h0;
      decode_valid <= 1'b0;
    end else if (valid_in) begin
      decoded_data <= data_in;
      decode_valid <= 1'b1;
      
      case (1'b1)
        is_csi: decoded_type <= {3'b000, csi_type_bit};
        is_dsi: decoded_type <= {2'b01, dsi_type_bits};
        is_i3c: decoded_type <= {2'b10, i3c_rffe_type_bits};
        is_rffe: decoded_type <= {2'b11, i3c_rffe_type_bits};
        default: begin
          decoded_type <= 4'h0;
          decode_valid <= 1'b0;
        end
      endcase
    end else begin
      decode_valid <= 1'b0;
    end
  end
endmodule

module packet_handler (
  input wire clk,
  input wire reset_n,
  input wire valid_in,
  input wire [3:0] protocol_type,
  input wire [31:0] data_in,
  output reg [7:0] packet_id,
  output reg [15:0] payload_length,
  output reg [15:0] bytes_received,
  output reg [3:0] state,
  output reg protocol_error
);

  // Pre-compute protocol type checks
  wire is_csi = (protocol_type == 4'd0);
  wire is_dsi = (protocol_type == 4'd1);
  wire is_i3c_rffe = (protocol_type == 4'd2 || protocol_type == 4'd3);
  
  // Pre-compute state transitions
  wire is_idle_state = (state == 4'd0);
  wire is_active_state = (state == 4'd1);
  
  // Pre-compute payload calculations
  wire [15:0] csi_payload = data_in[23:8];
  wire [15:0] dsi_payload = {8'h0, data_in[15:8]} << 1;
  wire [15:0] next_bytes = bytes_received + 16'd4;
  wire payload_complete = (next_bytes >= payload_length);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      protocol_error <= 1'b0;
      bytes_received <= 16'd0;
      packet_id <= 8'h0;
      payload_length <= 16'h0;
    end else if (valid_in) begin
      case (1'b1)
        is_csi: begin
          if (is_idle_state) begin
            packet_id <= data_in[7:0];
            payload_length <= csi_payload;
            bytes_received <= 16'd0;
            state <= 4'd1;
          end else if (is_active_state) begin
            bytes_received <= next_bytes;
            if (payload_complete) state <= 4'd0;
          end
        end
        
        is_dsi: begin
          if (is_idle_state) begin
            packet_id <= data_in[7:0];
            payload_length <= dsi_payload;
            bytes_received <= 16'd0;
            state <= 4'd1;
          end else if (is_active_state) begin
            bytes_received <= next_bytes;
            if (payload_complete) state <= 4'd0;
          end
        end
        
        is_i3c_rffe: begin
          state <= 4'd0;
        end
        
        default: begin
          protocol_error <= 1'b1;
          state <= 4'd0;
        end
      endcase
    end
  end
endmodule