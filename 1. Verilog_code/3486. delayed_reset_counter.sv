module delayed_reset_counter #(parameter WIDTH = 8, DELAY = 3)(
  input clk, rst_trigger,
  output reg [WIDTH-1:0] count
);
  reg [DELAY-1:0] delay_shift;
  wire delayed_reset = delay_shift[0];
  
  always @(posedge clk) begin
    delay_shift <= {rst_trigger, delay_shift[DELAY-1:1]};
    if (delayed_reset)
      count <= {WIDTH{1'b0}};
    else
      count <= count + 1'b1;
  end
endmodule