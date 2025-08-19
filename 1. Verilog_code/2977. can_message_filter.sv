module can_message_filter(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] filter_masks [0:3],
  input wire [10:0] filter_values [0:3],
  input wire [3:0] filter_enable,
  output reg frame_accepted
);
  reg [3:0] match;
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_accepted <= 0;
      match <= 0;
    end else if (id_valid) begin
      match <= 0;
      for (i = 0; i < 4; i = i + 1) begin
        if (filter_enable[i] && ((rx_id & filter_masks[i]) == filter_values[i]))
          match[i] <= 1;
      end
      frame_accepted <= (match != 0);
    end
  end
endmodule