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
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter <= 0;
      segment <= 0;
      prev_rx <= 1;
    end else begin
      prev_rx <= can_rx;
      if (prev_rx == 1 && can_rx == 0) begin
        bit_counter <= 0; // Hard sync
        segment <= 0;
      end else begin
        bit_counter <= (bit_counter == TICKS_PER_BIT-1) ? 0 : bit_counter + 1;
      end
    end
  end
endmodule