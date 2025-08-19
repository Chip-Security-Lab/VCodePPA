//SystemVerilog
module mipi_lane_multiplexer #(parameter LANES = 4) (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire valid_in,
  input wire [1:0] active_lanes,
  output reg [LANES-1:0] lane_data,
  output reg lane_valid
);

  // Stage 1: Input and Configuration
  reg [7:0] data_in_stage1;
  reg valid_in_stage1;
  reg [1:0] active_lanes_stage1;
  reg [2:0] bytes_per_cycle_stage1;
  
  // Stage 2: Data Collection
  reg [3:0] byte_counter_stage2;
  reg [31:0] data_buffer_stage2;
  reg valid_stage2;
  
  // Stage 3: Lane Assignment
  reg [31:0] data_buffer_stage3;
  reg [1:0] active_lanes_stage3;
  reg valid_stage3;
  
  // Stage 4: Output
  reg [LANES-1:0] lane_data_stage4;
  reg valid_stage4;

  // Stage 1: Input and Configuration
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_in_stage1 <= 8'd0;
      valid_in_stage1 <= 1'b0;
      active_lanes_stage1 <= 2'd0;
      case (active_lanes)
        2'b00: bytes_per_cycle_stage1 <= 3'd1;
        2'b01: bytes_per_cycle_stage1 <= 3'd2;
        2'b10: bytes_per_cycle_stage1 <= 3'd3;
        2'b11: bytes_per_cycle_stage1 <= 3'd4;
      endcase
    end else begin
      data_in_stage1 <= data_in;
      valid_in_stage1 <= valid_in;
      active_lanes_stage1 <= active_lanes;
    end
  end

  // Stage 2: Data Collection
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      byte_counter_stage2 <= 4'd0;
      data_buffer_stage2 <= 32'd0;
      valid_stage2 <= 1'b0;
    end else begin
      valid_stage2 <= 1'b0;
      if (valid_in_stage1) begin
        case (byte_counter_stage2)
          4'd0: data_buffer_stage2[7:0] <= data_in_stage1;
          4'd1: data_buffer_stage2[15:8] <= data_in_stage1;
          4'd2: data_buffer_stage2[23:16] <= data_in_stage1;
          4'd3: data_buffer_stage2[31:24] <= data_in_stage1;
        endcase
        
        byte_counter_stage2 <= byte_counter_stage2 + 1'b1;
        
        if (byte_counter_stage2 == bytes_per_cycle_stage1 - 1) begin
          byte_counter_stage2 <= 4'd0;
          valid_stage2 <= 1'b1;
        end
      end
    end
  end

  // Stage 3: Lane Assignment
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_buffer_stage3 <= 32'd0;
      active_lanes_stage3 <= 2'd0;
      valid_stage3 <= 1'b0;
    end else begin
      data_buffer_stage3 <= data_buffer_stage2;
      active_lanes_stage3 <= active_lanes_stage1;
      valid_stage3 <= valid_stage2;
    end
  end

  // Stage 4: Output
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      lane_data_stage4 <= {LANES{1'b0}};
      valid_stage4 <= 1'b0;
    end else begin
      valid_stage4 <= valid_stage3;
      if (valid_stage3) begin
        case (active_lanes_stage3)
          2'b00: lane_data_stage4 <= {3'b000, data_buffer_stage3[7:0]};
          2'b01: lane_data_stage4 <= {2'b00, data_buffer_stage3[15:8], data_buffer_stage3[7:0]};
          2'b10: lane_data_stage4 <= {1'b0, data_buffer_stage3[23:16], data_buffer_stage3[15:8], data_buffer_stage3[7:0]};
          2'b11: lane_data_stage4 <= {data_buffer_stage3[31:24], data_buffer_stage3[23:16], data_buffer_stage3[15:8], data_buffer_stage3[7:0]};
        endcase
      end
    end
  end

  // Output assignments
  assign lane_data = lane_data_stage4;
  assign lane_valid = valid_stage4;

endmodule