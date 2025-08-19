module reset_counter_alarm #(
  parameter ALARM_THRESHOLD = 4
) (
  input wire clk,
  input wire reset_in,
  input wire clear_counter,
  output reg alarm,
  output reg [3:0] reset_count
);
  reg reset_prev;
  
  always @(posedge clk) begin
    reset_prev <= reset_in;
    if (clear_counter)
      reset_count <= 4'd0;
    else if (reset_in && !reset_prev && reset_count < 4'hF)
      reset_count <= reset_count + 4'd1;
      
    alarm <= (reset_count >= ALARM_THRESHOLD);
  end
endmodule