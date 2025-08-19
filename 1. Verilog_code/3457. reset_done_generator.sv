module reset_done_generator (
  input wire clk,
  input wire reset_n,
  output reg reset_done
);
  always @(posedge clk) begin
    if (!reset_n)
      reset_done <= 0;
    else
      reset_done <= 1;
  end
endmodule
