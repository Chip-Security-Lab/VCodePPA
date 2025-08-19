module brownout_detector #(
  parameter LOW_THRESHOLD = 8'd85,
  parameter HIGH_THRESHOLD = 8'd95
)(
  input clk, enable,
  input [7:0] supply_voltage,
  output reg brownout_reset
);
  reg brownout_state = 0;
  
  always @(posedge clk) begin
    if (!enable)
      brownout_state <= 0;
    else if (supply_voltage < LOW_THRESHOLD)
      brownout_state <= 1;
    else if (supply_voltage > HIGH_THRESHOLD)
      brownout_state <= 0;
      
    brownout_reset <= brownout_state;
  end
endmodule