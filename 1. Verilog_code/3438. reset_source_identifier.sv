module reset_source_identifier (
  input wire clk,
  input wire sys_reset,
  input wire pwr_reset,
  input wire wdt_reset,
  input wire sw_reset,
  output reg [3:0] reset_source
);
  always @(posedge clk) begin
    if (pwr_reset)
      reset_source <= 4'h1;
    else if (wdt_reset)
      reset_source <= 4'h2;
    else if (sw_reset)
      reset_source <= 4'h3;
    else if (sys_reset)
      reset_source <= 4'h4;
    else if (!sys_reset && !pwr_reset && !wdt_reset && !sw_reset)
      reset_source <= 4'h0;
  end
endmodule