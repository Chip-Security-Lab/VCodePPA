module brownout_reset_detector #(
  parameter THRESHOLD = 8'h80
) (
  input wire clk,
  input wire [7:0] voltage_level,
  output reg brownout_reset
);
  reg [1:0] voltage_state;
  
  always @(posedge clk) begin
    voltage_state <= {voltage_state[0], voltage_level < THRESHOLD};
    brownout_reset <= &voltage_state;
  end
endmodule
