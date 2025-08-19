module reset_source_priority(
  input pwr_fail, watchdog_timeout, manual_btn, brownout,
  output reg [1:0] reset_cause,
  output wire system_reset
);
  assign system_reset = pwr_fail | watchdog_timeout | manual_btn | brownout;
  
  always @(*) begin
    if (pwr_fail)         reset_cause = 2'b00;
    else if (brownout)    reset_cause = 2'b01;
    else if (watchdog_timeout) reset_cause = 2'b10;
    else if (manual_btn)  reset_cause = 2'b11;
    else                  reset_cause = 2'b00;
  end
endmodule