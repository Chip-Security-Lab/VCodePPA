module reset_history_tracker(
  input clk, clear_history,
  input por_n, wdt_n, soft_n, ext_n,
  output reg [3:0] current_rst_src,
  output reg [15:0] reset_history
);
  wire [3:0] sources = {~ext_n, ~soft_n, ~wdt_n, ~por_n};
  reg [3:0] prev_sources = 4'b0000;
  
  always @(posedge clk) begin
    prev_sources <= sources;
    current_rst_src <= sources;
    
    if (clear_history)
      reset_history <= 16'h0;
    else if (|(sources & ~prev_sources))
      reset_history <= {reset_history[11:0], sources};
  end
endmodule