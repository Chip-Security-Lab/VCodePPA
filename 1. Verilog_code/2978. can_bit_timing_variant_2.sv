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
  // Constants calculation
  localparam integer TICKS_PER_BIT = (CLK_FREQ_MHZ * 1000) / CAN_BITRATE_KBPS;
  localparam integer SYNC_SEG = 1;
  localparam integer PROP_SEG = 1;
  localparam integer PHASE_SEG1 = 3;
  localparam integer PHASE_SEG2 = 3;
  
  // Segment boundaries for clearer code
  localparam integer SYNC_END = SYNC_SEG;
  localparam integer PROP_END = SYNC_SEG + PROP_SEG;
  localparam integer PHASE1_END = SYNC_SEG + PROP_SEG + PHASE_SEG1;
  localparam integer PHASE2_END = SYNC_SEG + PROP_SEG + PHASE_SEG1 + PHASE_SEG2;
  
  // Stage 1: Input synchronization and edge detection
  reg can_rx_stage1;
  reg can_rx_stage2;
  reg edge_detected_stage1;
  reg valid_stage1;
  
  // Stage 2: Counter control and segment calculation
  reg [7:0] bit_counter_stage2;
  reg [2:0] segment_stage2;
  reg valid_stage2;
  reg edge_detected_stage2;
  
  // Stage 3: Output generation
  reg sample_point_stage3;
  reg sync_edge_stage3;
  reg [2:0] segment_stage3;
  
  // Additional control signals for clearer conditionals
  reg is_end_of_bit;
  reg is_sync_seg;
  reg is_prop_seg;
  reg is_phase_seg1;
  reg is_phase_seg2;
  reg at_sample_point;
  
  // Pipeline Stage 1: Input synchronization and edge detection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_rx_stage1 <= 1'b1;
      can_rx_stage2 <= 1'b1;
      edge_detected_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      can_rx_stage1 <= can_rx;
      can_rx_stage2 <= can_rx_stage1;
      
      // Detect falling edge (simplified condition)
      edge_detected_stage1 <= (can_rx_stage2 & ~can_rx_stage1);
      
      // Control signal always valid after reset
      valid_stage1 <= 1'b1;
    end
  end
  
  // Pipeline Stage 2: Counter control and segment calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter_stage2 <= 8'h0;
      segment_stage2 <= 3'h0;
      valid_stage2 <= 1'b0;
      edge_detected_stage2 <= 1'b0;
    end else begin
      edge_detected_stage2 <= edge_detected_stage1;
      valid_stage2 <= valid_stage1;
      
      // Calculate control signals
      is_end_of_bit = (bit_counter_stage2 == TICKS_PER_BIT-1);
      
      // Update bit counter based on conditions
      if (edge_detected_stage1) begin
        // Hard sync
        bit_counter_stage2 <= 8'h0;
        segment_stage2 <= 3'h1; // Reset to SYNC_SEG
      end else if (valid_stage1) begin
        if (is_end_of_bit) begin
          bit_counter_stage2 <= 8'h0;
          segment_stage2 <= 3'h1; // Reset to SYNC_SEG
        end else begin
          bit_counter_stage2 <= bit_counter_stage2 + 1'b1;
          
          // Calculate segment indicators
          is_sync_seg = (bit_counter_stage2 < SYNC_END);
          is_prop_seg = (bit_counter_stage2 >= SYNC_END) && (bit_counter_stage2 < PROP_END);
          is_phase_seg1 = (bit_counter_stage2 >= PROP_END) && (bit_counter_stage2 < PHASE1_END);
          is_phase_seg2 = (bit_counter_stage2 >= PHASE1_END) && (bit_counter_stage2 < PHASE2_END);
          
          // Set segment based on indicators
          if (is_sync_seg)
            segment_stage2 <= 3'h1; // SYNC_SEG
          else if (is_prop_seg)
            segment_stage2 <= 3'h2; // PROP_SEG
          else if (is_phase_seg1)
            segment_stage2 <= 3'h3; // PHASE_SEG1
          else if (is_phase_seg2)
            segment_stage2 <= 3'h4; // PHASE_SEG2
          else
            segment_stage2 <= 3'h0; // Invalid segment
        end
      end
    end
  end
  
  // Pipeline Stage 3: Output generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sample_point_stage3 <= 1'b0;
      sync_edge_stage3 <= 1'b0;
      segment_stage3 <= 3'h0;
      
      sample_point <= 1'b0;
      sync_edge <= 1'b0;
      segment <= 3'h0;
    end else begin
      // Detect sample point (end of PHASE_SEG1)
      at_sample_point = (bit_counter_stage2 == (PHASE1_END - 1));
      
      // Set stage 3 signals
      sample_point_stage3 <= at_sample_point;
      sync_edge_stage3 <= edge_detected_stage2;
      segment_stage3 <= segment_stage2;
      
      // Register outputs for clean timing
      sample_point <= sample_point_stage3;
      sync_edge <= sync_edge_stage3;
      segment <= segment_stage3;
    end
  end
endmodule