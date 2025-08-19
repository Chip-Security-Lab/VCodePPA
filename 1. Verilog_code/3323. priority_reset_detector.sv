module priority_reset_detector(
  input clk, enable,
  input [7:0] reset_sources, // Active high
  input [7:0][2:0] priorities, // Lower value = higher priority
  output reg [2:0] active_priority,
  output reg [7:0] priority_encoded,
  output reg reset_out
);
  integer i, highest_idx;
  reg [2:0] highest_priority;
  
  always @(posedge clk) begin
    if (!enable) begin
      active_priority <= 3'h7;
      priority_encoded <= 8'h00;
      reset_out <= 1'b0;
    end else begin
      highest_priority <= 3'h7;
      highest_idx <= 0;
      
      for (i = 0; i < 8; i = i + 1) begin
        if (reset_sources[i] && (priorities[i] < highest_priority)) begin
          highest_priority <= priorities[i];
          highest_idx <= i;
        end
      end
      
      active_priority <= highest_priority;
      priority_encoded <= reset_sources ? (1 << highest_idx) : 8'h00;
      reset_out <= |reset_sources;
    end
  end
endmodule