//SystemVerilog
module mipi_lane_multiplexer #(parameter LANES = 4) (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire valid_in,
  input wire [1:0] active_lanes,
  output reg [LANES-1:0] lane_data,
  output reg lane_valid
);

  reg [3:0] byte_counter;
  reg [31:0] data_buffer;
  reg [1:0] state;
  reg [2:0] bytes_per_cycle;
  
  // LUT for bytes_per_cycle calculation
  reg [2:0] bytes_per_cycle_lut [0:3];
  initial begin
    bytes_per_cycle_lut[0] = 3'd1;
    bytes_per_cycle_lut[1] = 3'd2; 
    bytes_per_cycle_lut[2] = 3'd3;
    bytes_per_cycle_lut[3] = 3'd4;
  end

  // LUT for lane data assignment
  reg [LANES-1:0] lane_data_lut [0:3];
  initial begin
    lane_data_lut[0] = {3'b000, 8'b0};
    lane_data_lut[1] = {2'b00, 16'b0};
    lane_data_lut[2] = {1'b0, 24'b0};
    lane_data_lut[3] = 32'b0;
  end

  // Reset and initialization logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      byte_counter <= 4'd0;
      lane_valid <= 1'b0;
      state <= 2'd0;
      bytes_per_cycle <= bytes_per_cycle_lut[active_lanes];
    end
  end

  // Data buffer update logic
  always @(posedge clk) begin
    if (valid_in) begin
      case (byte_counter)
        4'd0: data_buffer[7:0] <= data_in;
        4'd1: data_buffer[15:8] <= data_in;
        4'd2: data_buffer[23:16] <= data_in;
        4'd3: data_buffer[31:24] <= data_in;
      endcase
    end
  end

  // Byte counter update logic
  always @(posedge clk) begin
    if (valid_in) begin
      byte_counter <= byte_counter + 1'b1;
      if (byte_counter == bytes_per_cycle - 1) begin
        byte_counter <= 4'd0;
      end
    end
  end

  // Lane data and valid signal generation
  always @(posedge clk) begin
    lane_valid <= 1'b0;
    if (valid_in && byte_counter == bytes_per_cycle - 1) begin
      lane_data <= lane_data_lut[active_lanes] | 
                  (active_lanes == 2'b00 ? {3'b000, data_buffer[7:0]} :
                   active_lanes == 2'b01 ? {2'b00, data_buffer[15:8], data_buffer[7:0]} :
                   active_lanes == 2'b10 ? {1'b0, data_buffer[23:16], data_buffer[15:8], data_buffer[7:0]} :
                   {data_buffer[31:24], data_buffer[23:16], data_buffer[15:8], data_buffer[7:0]});
      lane_valid <= 1'b1;
    end
  end

endmodule