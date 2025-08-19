//SystemVerilog
module freq_divider_reset #(parameter DIVISOR = 10)(
  input wire clk_in, reset,
  output reg clk_out
);
  localparam COUNT_WIDTH = $clog2(DIVISOR);
  reg [COUNT_WIDTH-1:0] counter;
  
  always @(posedge clk_in) begin
    if (reset) begin
      counter <= {COUNT_WIDTH{1'b0}};
      clk_out <= 1'b0;
    end else if (counter >= DIVISOR - 1) begin
      counter <= {COUNT_WIDTH{1'b0}};
      clk_out <= ~clk_out;
    end else begin
      counter <= counter + 1'b1;
    end
  end
endmodule