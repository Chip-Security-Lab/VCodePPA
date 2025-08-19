module reset_recovery_monitor #(
  parameter MIN_STABLE_CYCLES = 16
) (
  input wire clk,
  input wire reset_n,
  output reg system_stable
);
  reg [$clog2(MIN_STABLE_CYCLES)-1:0] stable_counter;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      stable_counter <= 0;
      system_stable <= 1'b0;
    end else begin
      if (stable_counter < MIN_STABLE_CYCLES-1)
        stable_counter <= stable_counter + 1;
      system_stable <= (stable_counter == MIN_STABLE_CYCLES-1);
    end
  end
endmodule