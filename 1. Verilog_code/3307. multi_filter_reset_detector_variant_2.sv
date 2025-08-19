//SystemVerilog
module multi_filter_reset_detector(
  input  wire        clock,
  input  wire        reset_n,
  input  wire [3:0]  reset_sources,
  input  wire [3:0]  filter_enable,
  output reg  [3:0]  filtered_resets
);
  reg [2:0] filter_counters [3:0];

  integer i;

  // Optimized counter logic for all channels
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      for (i = 0; i < 4; i = i + 1)
        filter_counters[i] <= 3'b000;
    end else begin
      for (i = 0; i < 4; i = i + 1) begin
        if (filter_enable[i] & reset_sources[i]) begin
          // Use saturating increment with bitwise logic for efficiency
          filter_counters[i] <= filter_counters[i] | ((~&filter_counters[i]) ? (filter_counters[i] + 3'b001) : 3'b000);
        end else begin
          filter_counters[i] <= 3'b000;
        end
      end
    end
  end

  // Optimized output logic for all channels
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      filtered_resets <= 4'b0000;
    end else begin
      // Vector comparison for efficiency
      filtered_resets[0] <= &filter_counters[0];
      filtered_resets[1] <= &filter_counters[1];
      filtered_resets[2] <= &filter_counters[2];
      filtered_resets[3] <= &filter_counters[3];
    end
  end

endmodule