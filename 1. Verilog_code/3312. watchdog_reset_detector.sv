module watchdog_reset_detector #(parameter TIMEOUT = 16'hFFFF)(
  input clk, enable, watchdog_kick,
  input ext_reset_n, pwr_reset_n,
  output reg system_reset,
  output reg [1:0] reset_source
);
  reg [15:0] watchdog_counter = 16'h0000;
  wire watchdog_timeout = (watchdog_counter >= TIMEOUT);
  wire ext_reset = ~ext_reset_n, pwr_reset = ~pwr_reset_n;
  
  always @(posedge clk) begin
    if (!enable)
      watchdog_counter <= 16'h0000;
    else if (watchdog_kick)
      watchdog_counter <= 16'h0000;
    else
      watchdog_counter <= watchdog_counter + 16'h0001;
      
    system_reset <= watchdog_timeout | ext_reset | pwr_reset;
    
    if (pwr_reset)       reset_source <= 2'b00;
    else if (ext_reset)  reset_source <= 2'b01;
    else if (watchdog_timeout) reset_source <= 2'b10;
    else                 reset_source <= 2'b11;
  end
endmodule