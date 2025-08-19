module reset_timeout_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_timeout_error
);
  reg [7:0] timeout;

  always @(posedge clk) begin
    if (!reset_n) begin
      timeout <= 8'd0;
      reset_timeout_error <= 0;
    end else if (timeout < 8'hFF) begin
      timeout <= timeout + 1;
    end else begin
      reset_timeout_error <= 1;
    end
  end
endmodule
