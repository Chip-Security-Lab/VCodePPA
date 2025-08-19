module reset_startup_delay (
  input wire clk,
  input wire reset_n,
  output reg system_ready
);
  reg [7:0] delay_counter;

  always @(posedge clk) begin
    if (!reset_n)
      delay_counter <= 0;
    else if (delay_counter < 8'hFF)
      delay_counter <= delay_counter + 1;

    if (delay_counter == 8'hFF)
      system_ready <= 1;
  end
endmodule
