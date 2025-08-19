module watchdog_reset #(
  parameter TIMEOUT = 1024
) (
  input wire clk,
  input wire watchdog_kick,
  input wire rst_n,
  output reg watchdog_rst
);
  reg [$clog2(TIMEOUT)-1:0] counter;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 0;
      watchdog_rst <= 1'b0;
    end else begin
      if (watchdog_kick)
        counter <= 0;
      else if (counter < TIMEOUT-1)
        counter <= counter + 1;
      watchdog_rst <= (counter == TIMEOUT-1);
    end
  end
endmodule