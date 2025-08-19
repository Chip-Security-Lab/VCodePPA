module async_reset_status (
  input wire clk,
  input wire reset,
  output wire reset_active,
  output reg [3:0] reset_count
);
  assign reset_active = reset;
  
  always @(posedge clk or posedge reset) begin
    if (reset)
      reset_count <= 4'd0;
    else if (reset_count < 4'hF)
      reset_count <= reset_count + 4'd1;
  end
endmodule