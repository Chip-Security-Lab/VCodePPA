module watchdog_reset #(parameter TIMEOUT = 1000)(
  input clk, ext_rst_n, watchdog_clear,
  output reg watchdog_rst
);
  reg [$clog2(TIMEOUT)-1:0] timer;
  
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      timer <= 0;
      watchdog_rst <= 0;
    end else if (watchdog_clear) begin
      timer <= 0;
      watchdog_rst <= 0;
    end else if (timer < TIMEOUT - 1)
      timer <= timer + 1;
    else
      watchdog_rst <= 1;
  end
endmodule