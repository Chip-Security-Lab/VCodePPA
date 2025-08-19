//SystemVerilog
module multi_filter_reset_detector(
  input  wire        clock,
  input  wire        reset_n,
  input  wire [3:0]  reset_sources,
  input  wire [3:0]  filter_enable,
  output reg  [3:0]  filtered_resets
);
  reg [2:0] filter_counters [3:0];
  integer idx;

  reg [2:0] next_filter_counter;
  reg       next_filtered_reset;

  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      for (idx = 0; idx < 4; idx = idx + 1) begin
        filter_counters[idx] <= 3'b000;
        filtered_resets[idx] <= 1'b0;
      end
    end else begin
      for (idx = 0; idx < 4; idx = idx + 1) begin
        // Explicit multiplexer for filter_counters update
        if (reset_sources[idx] & filter_enable[idx]) begin
          if (filter_counters[idx] != 3'b111) begin
            next_filter_counter = filter_counters[idx] + 1'b1;
          end else begin
            next_filter_counter = 3'b111;
          end
        end else begin
          next_filter_counter = 3'b000;
        end
        filter_counters[idx] <= next_filter_counter;

        // Explicit multiplexer for filtered_resets update
        if ((filter_counters[idx] == 3'b110) && (reset_sources[idx] & filter_enable[idx])) begin
          next_filtered_reset = 1'b1;
        end else begin
          next_filtered_reset = 1'b0;
        end
        filtered_resets[idx] <= next_filtered_reset;
      end
    end
  end
endmodule