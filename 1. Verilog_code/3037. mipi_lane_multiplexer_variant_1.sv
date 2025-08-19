//SystemVerilog
module mipi_lane_multiplexer #(parameter LANES = 4) (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire valid_in,
  input wire [1:0] active_lanes,
  output reg [LANES-1:0] lane_data,
  output reg lane_valid
);

  wire [3:0] byte_counter;
  wire [31:0] data_buffer;
  wire [2:0] bytes_per_cycle;
  wire buffer_full;

  byte_counter_ctrl u_byte_counter_ctrl (
    .clk(clk),
    .reset_n(reset_n),
    .valid_in(valid_in),
    .bytes_per_cycle(bytes_per_cycle),
    .byte_counter(byte_counter),
    .buffer_full(buffer_full)
  );

  data_buffer_ctrl u_data_buffer_ctrl (
    .clk(clk),
    .reset_n(reset_n),
    .valid_in(valid_in),
    .data_in(data_in),
    .byte_counter(byte_counter),
    .data_buffer(data_buffer)
  );

  lane_config_ctrl u_lane_config_ctrl (
    .clk(clk),
    .reset_n(reset_n),
    .active_lanes(active_lanes),
    .bytes_per_cycle(bytes_per_cycle)
  );

  lane_output_ctrl u_lane_output_ctrl (
    .clk(clk),
    .reset_n(reset_n),
    .buffer_full(buffer_full),
    .data_buffer(data_buffer),
    .active_lanes(active_lanes),
    .lane_data(lane_data),
    .lane_valid(lane_valid)
  );

endmodule

module byte_counter_ctrl (
  input wire clk, reset_n,
  input wire valid_in,
  input wire [2:0] bytes_per_cycle,
  output reg [3:0] byte_counter,
  output reg buffer_full
);

  wire [3:0] next_byte_counter;
  wire next_buffer_full;

  assign next_byte_counter = (!reset_n) ? 4'd0 :
                           (valid_in) ? ((byte_counter == bytes_per_cycle - 1) ? 4'd0 : byte_counter + 1'b1) :
                           byte_counter;

  assign next_buffer_full = (!reset_n) ? 1'b0 :
                           (valid_in && (byte_counter == bytes_per_cycle - 1)) ? 1'b1 :
                           1'b0;

  always @(posedge clk) begin
    byte_counter <= next_byte_counter;
    buffer_full <= next_buffer_full;
  end

endmodule

module data_buffer_ctrl (
  input wire clk, reset_n,
  input wire valid_in,
  input wire [7:0] data_in,
  input wire [3:0] byte_counter,
  output reg [31:0] data_buffer
);

  wire [31:0] next_data_buffer;
  wire [31:0] shifted_data;

  assign shifted_data = data_in << (byte_counter * 8);
  assign next_data_buffer = (!reset_n) ? 32'd0 :
                           (valid_in) ? (data_buffer | shifted_data) :
                           data_buffer;

  always @(posedge clk) begin
    data_buffer <= next_data_buffer;
  end

endmodule

module lane_config_ctrl (
  input wire clk, reset_n,
  input wire [1:0] active_lanes,
  output reg [2:0] bytes_per_cycle
);

  wire [2:0] next_bytes_per_cycle;

  assign next_bytes_per_cycle = (!reset_n) ? 3'd1 :
                               active_lanes + 1'b1;

  always @(posedge clk) begin
    bytes_per_cycle <= next_bytes_per_cycle;
  end

endmodule

module lane_output_ctrl (
  input wire clk, reset_n,
  input wire buffer_full,
  input wire [31:0] data_buffer,
  input wire [1:0] active_lanes,
  output reg [3:0] lane_data,
  output reg lane_valid
);

  wire [3:0] next_lane_data;
  wire next_lane_valid;
  wire [31:0] masked_data;
  wire [31:0] mask_value;
  wire [31:0] mask_complement;
  wire [31:0] mask_result;

  // Two's complement subtraction implementation
  // Instead of: ((32'hFF << (active_lanes * 8)) - 1)
  // We use: ~((~32'h0) << (active_lanes * 8)) + 1
  
  // Generate the mask value using two's complement
  assign mask_value = 32'h0;
  assign mask_complement = ~mask_value;
  assign mask_result = ~((mask_complement << (active_lanes * 8)));
  
  // Apply the mask to data_buffer
  assign masked_data = data_buffer & mask_result;
  
  assign next_lane_data = (!reset_n) ? 4'd0 :
                         (buffer_full) ? masked_data[3:0] :
                         lane_data;

  assign next_lane_valid = (!reset_n) ? 1'b0 :
                          buffer_full;

  always @(posedge clk) begin
    lane_data <= next_lane_data;
    lane_valid <= next_lane_valid;
  end

endmodule