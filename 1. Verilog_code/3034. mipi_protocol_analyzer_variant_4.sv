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
  
  // Buffered input signals
  reg [31:0] data_in_buf;
  reg valid_in_buf;
  reg [3:0] protocol_type_buf;
  
  // Brent-Kung Adder signals with buffering
  reg [31:0] g, p;
  reg [31:0] g_level1, p_level1;
  wire [31:0] g_level2, p_level2;
  wire [31:0] g_level3, p_level3;
  wire [31:0] g_level4, p_level4;
  wire [31:0] g_level5, p_level5;
  wire [31:0] sum;

  // Input buffering
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_in_buf <= 32'd0;
      valid_in_buf <= 1'b0;
      protocol_type_buf <= 4'd0;
    end else begin
      data_in_buf <= data_in;
      valid_in_buf <= valid_in;
      protocol_type_buf <= protocol_type;
    end
  end

  // Generate and Propagate computation with buffering
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      g <= 32'd0;
      p <= 32'd0;
    end else begin
      for (int i = 0; i < 32; i = i + 1) begin
        g[i] <= data_in_buf[i] & 4'b1;
        p[i] <= data_in_buf[i] ^ 4'b1;
      end
    end
  end

  // Level 1 with buffering
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      g_level1 <= 32'd0;
      p_level1 <= 32'd0;
    end else begin
      for (int j = 0; j < 16; j = j + 1) begin
        g_level1[j*2+1] <= g[j*2+1] | (p[j*2+1] & g[j*2]);
        p_level1[j*2+1] <= p[j*2+1] & p[j*2];
      end
    end
  end

  // Level 2
  generate
    for (genvar j = 0; j < 8; j = j + 1) begin : level2
      assign g_level2[j*4+3] = g_level1[j*4+3] | (p_level1[j*4+3] & g_level1[j*4+1]);
      assign p_level2[j*4+3] = p_level1[j*4+3] & p_level1[j*4+1];
    end
  endgenerate

  // Level 3
  generate
    for (genvar j = 0; j < 4; j = j + 1) begin : level3
      assign g_level3[j*8+7] = g_level2[j*8+7] | (p_level2[j*8+7] & g_level2[j*8+3]);
      assign p_level3[j*8+7] = p_level2[j*8+7] & p_level2[j*8+3];
    end
  endgenerate

  // Level 4
  generate
    for (genvar j = 0; j < 2; j = j + 1) begin : level4
      assign g_level4[j*16+15] = g_level3[j*16+15] | (p_level3[j*16+15] & g_level3[j*16+7]);
      assign p_level4[j*16+15] = p_level3[j*16+15] & p_level3[j*16+7];
    end
  endgenerate

  // Level 5
  assign g_level5[31] = g_level4[31] | (p_level4[31] & g_level4[15]);
  assign p_level5[31] = p_level4[31] & p_level4[15];

  // Sum computation
  assign sum[0] = p[0];
  generate
    for (genvar i = 1; i < 32; i = i + 1) begin : sum_gen
      assign sum[i] = p[i] ^ g[i-1];
    end
  endgenerate

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
    end else if (valid_in_buf) begin
      case (protocol_type_buf)
        4'd0: begin
          if (state == 4'd0) begin
            packet_id <= data_in_buf[7:0];
            payload_length <= data_in_buf[23:8];
            bytes_received <= 16'd0;
            state <= 4'd1;
            decode_valid <= 1'b0;
          end else begin
            bytes_received <= sum[15:0];
            decoded_data <= data_in_buf;
            decoded_type <= {3'b000, (data_in_buf[31:24] == 8'hFF) ? 1'b1 : 1'b0};
            decode_valid <= 1'b1;
            if (sum[15:0] >= payload_length) state <= 4'd0;
          end
        end
        
        4'd1: begin
          if (state == 4'd0) begin
            packet_id <= data_in_buf[7:0];
            payload_length <= data_in_buf[15:8] * 2;
            bytes_received <= 16'd0;
            state <= 4'd1;
            decode_valid <= 1'b0;
          end else begin
            bytes_received <= sum[15:0];
            decoded_data <= data_in_buf;
            decoded_type <= {2'b01, data_in_buf[31:30]};
            decode_valid <= 1'b1;
            if (sum[15:0] >= payload_length) state <= 4'd0;
          end
        end
        
        4'd2: begin
          decoded_data <= data_in_buf;
          decoded_type <= {2'b10, data_in_buf[1:0]};
          decode_valid <= 1'b1;
          state <= 4'd0;
        end
        
        4'd3: begin
          decoded_data <= data_in_buf;
          decoded_type <= {2'b11, data_in_buf[1:0]};
          decode_valid <= 1'b1;
          state <= 4'd0;
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