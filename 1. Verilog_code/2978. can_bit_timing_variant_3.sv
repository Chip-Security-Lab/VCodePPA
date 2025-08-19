//SystemVerilog
module can_bit_timing #(
  parameter CLK_FREQ_MHZ = 20,
  parameter CAN_BITRATE_KBPS = 500
)(
  input wire clk, rst_n,
  input wire can_rx,
  output reg sample_point, sync_edge,
  output reg [2:0] segment
);
  localparam integer TICKS_PER_BIT = (CLK_FREQ_MHZ * 1000) / CAN_BITRATE_KBPS;
  localparam integer SYNC_SEG = 1;
  localparam integer PROP_SEG = 1;
  localparam integer PHASE_SEG1 = 3;
  localparam integer PHASE_SEG2 = 3;
  
  reg [7:0] bit_counter;
  reg prev_rx;
  wire hard_sync_detected;
  
  // Edge detection logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_rx <= 1'b1;
    end else begin
      prev_rx <= can_rx;
    end
  end
  
  // Hard sync detection
  assign hard_sync_detected = (prev_rx == 1'b1 && can_rx == 1'b0);
  
  // Bit counter management
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter <= 8'h0;
    end else if (hard_sync_detected) begin
      bit_counter <= 8'h0; // Reset on hard sync
    end else if (bit_counter == TICKS_PER_BIT-1) begin
      bit_counter <= 8'h0; // Reset at end of bit time
    end else begin
      bit_counter <= bit_counter + 1'b1;
    end
  end
  
  // Segment identification
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      segment <= 3'b000;
    end else if (hard_sync_detected) begin
      segment <= 3'b000; // SYNC_SEG
    end else begin
      case (bit_counter)
        SYNC_SEG:                             segment <= 3'b001; // PROP_SEG
        SYNC_SEG + PROP_SEG:                  segment <= 3'b010; // PHASE_SEG1
        SYNC_SEG + PROP_SEG + PHASE_SEG1:     segment <= 3'b011; // PHASE_SEG2
        default:                              segment <= segment; // Hold current segment
      endcase
    end
  end
  
  // Sync edge signal generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_edge <= 1'b0;
    end else begin
      sync_edge <= hard_sync_detected;
    end
  end
  
  // Sample point generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sample_point <= 1'b0;
    end else if (hard_sync_detected) begin
      sample_point <= 1'b0;
    end else if (bit_counter == SYNC_SEG + PROP_SEG + PHASE_SEG1) begin
      sample_point <= 1'b1; // Set at sample point
    end else if (bit_counter == SYNC_SEG + PROP_SEG + PHASE_SEG1 + 1) begin
      sample_point <= 1'b0; // Clear after sample point
    end
  end
  
endmodule