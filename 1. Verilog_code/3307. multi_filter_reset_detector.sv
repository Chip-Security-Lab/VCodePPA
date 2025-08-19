module multi_filter_reset_detector(
  input clock, reset_n,
  input [3:0] reset_sources,
  input [3:0] filter_enable,
  output reg [3:0] filtered_resets
);
  reg [3:0][2:0] filter_counters;
  integer i;
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      filter_counters <= {4{3'b000}};
      filtered_resets <= 4'b0000;
    end else begin
      for (i = 0; i < 4; i = i + 1) begin
        if (reset_sources[i] && filter_enable[i]) begin
          if (filter_counters[i] < 3'b111)
            filter_counters[i] <= filter_counters[i] + 1;
        end else
          filter_counters[i] <= 3'b000;
        filtered_resets[i] <= (filter_counters[i] == 3'b111);
      end
    end
  end
endmodule