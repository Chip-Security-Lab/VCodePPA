module can_filter_bank #(
  parameter NUM_FILTERS = 4
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [NUM_FILTERS-1:0] filter_enable,
  input wire [10:0] filter_id [0:NUM_FILTERS-1],
  input wire [10:0] filter_mask [0:NUM_FILTERS-1],
  output reg id_match,
  output reg [NUM_FILTERS-1:0] match_filter
);
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 0;
      match_filter <= 0;
    end else if (id_valid) begin
      id_match <= 0;
      match_filter <= 0;
      
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        if (filter_enable[i] && ((rx_id & filter_mask[i]) == (filter_id[i] & filter_mask[i]))) begin
          match_filter[i] <= 1;
          id_match <= 1;
        end
      end
    end
  end
endmodule