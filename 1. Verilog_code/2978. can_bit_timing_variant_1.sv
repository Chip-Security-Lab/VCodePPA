//SystemVerilog
//IEEE 1364-2005 Verilog
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
  
  // Precompute segment boundaries for improved timing
  localparam integer SYNC_END = SYNC_SEG - 1;
  localparam integer PROP_END = SYNC_SEG + PROP_SEG - 1;
  localparam integer PHASE1_END = SYNC_SEG + PROP_SEG + PHASE_SEG1 - 1;
  localparam integer BIT_END = TICKS_PER_BIT - 1;
  
  reg [7:0] bit_counter;
  reg prev_rx;
  wire falling_edge;
  
  // Simplified edge detection
  assign falling_edge = prev_rx & ~can_rx;
  
  // Optimized segment determination using case statement
  always @(*) begin
    case (1'b1)
      bit_counter <= SYNC_END:     segment = 3'd0;  // SYNC segment
      bit_counter <= PROP_END:     segment = 3'd1;  // PROP segment
      bit_counter <= PHASE1_END:   segment = 3'd2;  // PHASE1 segment
      bit_counter <= BIT_END:      segment = 3'd3;  // PHASE2 segment
      default:                     segment = 3'd4;  // End of bit
    endcase
  end
  
  // Direct assignment for sample point
  always @(*) begin
    sample_point = (bit_counter == PHASE1_END);
  end
  
  // Direct assignment for sync edge
  always @(*) begin
    sync_edge = falling_edge;
  end
  
  // Optimized bit counter logic with consolidated transitions
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter <= 8'b0;
      prev_rx <= 1'b1;
    end
    else begin
      prev_rx <= can_rx;
      
      if (falling_edge)
        bit_counter <= 8'b0;                // Hard sync on falling edge
      else if (bit_counter >= BIT_END)
        bit_counter <= 8'b0;                // Wrap around at end of bit
      else
        bit_counter <= bit_counter + 8'b1;  // Normal increment
    end
  end
  
endmodule