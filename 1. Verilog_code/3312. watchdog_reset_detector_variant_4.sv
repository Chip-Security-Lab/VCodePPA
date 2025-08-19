//SystemVerilog
module watchdog_reset_detector #(parameter TIMEOUT = 16'hFFFF)(
  input  wire        clk,
  input  wire        enable,
  input  wire        watchdog_kick,
  input  wire        ext_reset_n,
  input  wire        pwr_reset_n,
  output reg         system_reset,
  output reg  [1:0]  reset_source
);
  reg [15:0] watchdog_counter = 16'h0000;

  reg        pwr_reset_active_r;
  reg        ext_reset_active_r;
  reg        watchdog_timeout_r;

  wire ext_reset_active = ~ext_reset_n;
  wire pwr_reset_active = ~pwr_reset_n;

  wire watchdog_timeout;
  assign watchdog_timeout = (watchdog_counter == TIMEOUT) | (watchdog_counter > TIMEOUT);

  always @(posedge clk) begin
    if (!enable || watchdog_kick)
      watchdog_counter <= 16'h0000;
    else if (!watchdog_timeout)
      watchdog_counter <= watchdog_counter + 16'h0001;
  end

  always @(posedge clk) begin
    pwr_reset_active_r    <= pwr_reset_active;
    ext_reset_active_r    <= ext_reset_active;
    watchdog_timeout_r    <= watchdog_timeout;
  end

  always @(posedge clk) begin
    system_reset <= pwr_reset_active_r | ext_reset_active_r | watchdog_timeout_r;

    casex ({pwr_reset_active_r, ext_reset_active_r, watchdog_timeout_r})
      3'b1xx: reset_source <= 2'b00; // Power-on reset has highest priority
      3'b01x: reset_source <= 2'b01; // External reset
      3'b001: reset_source <= 2'b10; // Watchdog timeout
      default: reset_source <= 2'b11;
    endcase
  end
endmodule