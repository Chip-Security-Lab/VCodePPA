//SystemVerilog
module reset_source_priority(
  input  wire pwr_fail,
  input  wire watchdog_timeout,
  input  wire manual_btn,
  input  wire brownout,
  output reg  [1:0] reset_cause,
  output wire system_reset
);

  wire is_pwr_fail;
  wire is_brownout;
  wire is_watchdog_timeout;
  wire is_manual_btn;

  assign is_pwr_fail          = pwr_fail;
  assign is_brownout          = ~is_pwr_fail         & brownout;
  assign is_watchdog_timeout  = ~is_pwr_fail & ~is_brownout         & watchdog_timeout;
  assign is_manual_btn        = ~is_pwr_fail & ~is_brownout & ~is_watchdog_timeout & manual_btn;

  assign system_reset = pwr_fail | watchdog_timeout | manual_btn | brownout;

  always @(*) begin
    if (is_pwr_fail) begin
      reset_cause = 2'b00;
    end else if (is_brownout) begin
      reset_cause = 2'b01;
    end else if (is_watchdog_timeout) begin
      reset_cause = 2'b10;
    end else if (is_manual_btn) begin
      reset_cause = 2'b11;
    end else begin
      reset_cause = 2'b00;
    end
  end

endmodule