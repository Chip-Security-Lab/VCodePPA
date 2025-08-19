//SystemVerilog
module reset_history_tracker(
  input clk,
  input clear_history,
  input por_n,
  input wdt_n,
  input soft_n,
  input ext_n,
  output reg [3:0] current_rst_src,
  output reg [15:0] reset_history
);
  wire [3:0] reset_sources_unbuf = {~ext_n, ~soft_n, ~wdt_n, ~por_n};

  // First stage buffer for high fanout reset_sources
  reg [3:0] reset_sources_buf1;
  // Second stage buffer for further load balancing
  reg [3:0] reset_sources_buf2;

  reg [3:0] prev_reset_sources = 4'b0000;
  wire [3:0] new_reset_event;

  // Buffering reset_sources to reduce fanout
  always @(posedge clk) begin
    reset_sources_buf1 <= reset_sources_unbuf;
    reset_sources_buf2 <= reset_sources_buf1;
  end

  assign new_reset_event = reset_sources_buf2 & ~prev_reset_sources;

  always @(posedge clk) begin
    prev_reset_sources <= reset_sources_buf2;
    current_rst_src <= reset_sources_buf2;

    case ({clear_history, |new_reset_event})
      2'b10: reset_history <= 16'h0000;
      2'b01: reset_history <= {reset_history[11:0], reset_sources_buf2};
      default: reset_history <= reset_history;
    endcase
  end
endmodule