module mipi_lane_multiplexer #(parameter LANES = 4) (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire valid_in,
  input wire [1:0] active_lanes, // 00: 1 lane, 01: 2 lanes, 10: 3 lanes, 11: 4 lanes
  output reg [LANES-1:0] lane_data,
  output reg lane_valid
);
  reg [3:0] byte_counter;
  reg [31:0] data_buffer;
  reg [1:0] state;
  reg [2:0] bytes_per_cycle;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      byte_counter <= 4'd0;
      lane_valid <= 1'b0;
      state <= 2'd0;
      
      case (active_lanes)
        2'b00: bytes_per_cycle <= 3'd1;
        2'b01: bytes_per_cycle <= 3'd2;
        2'b10: bytes_per_cycle <= 3'd3;
        2'b11: bytes_per_cycle <= 3'd4;
      endcase
    end else begin
      lane_valid <= 1'b0;
      
      if (valid_in) begin
        case (byte_counter)
          4'd0: data_buffer[7:0] <= data_in;
          4'd1: data_buffer[15:8] <= data_in;
          4'd2: data_buffer[23:16] <= data_in;
          4'd3: data_buffer[31:24] <= data_in;
        endcase
        
        byte_counter <= byte_counter + 1'b1;
        
        if (byte_counter == bytes_per_cycle - 1) begin
          byte_counter <= 4'd0;
          
          // Assign data to lanes based on active_lanes
          case (active_lanes)
            2'b00: lane_data <= {3'b000, data_buffer[7:0]};
            2'b01: lane_data <= {2'b00, data_buffer[15:8], data_buffer[7:0]};
            2'b10: lane_data <= {1'b0, data_buffer[23:16], data_buffer[15:8], data_buffer[7:0]};
            2'b11: lane_data <= {data_buffer[31:24], data_buffer[23:16], data_buffer[15:8], data_buffer[7:0]};
          endcase
          
          lane_valid <= 1'b1;
        end
      end
    end
  end
endmodule