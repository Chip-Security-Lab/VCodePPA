module reset_handshake_monitor (
  input wire clk,
  input wire reset_req,
  input wire reset_ack,
  output reg reset_active,
  output reg timeout_error
);
  reg [7:0] timeout_counter;
  
  always @(posedge clk) begin
    if (reset_req && !reset_active) begin
      reset_active <= 1'b1;
      timeout_counter <= 8'd0;
      timeout_error <= 1'b0;
    end else if (reset_active && !reset_ack) begin
      if (timeout_counter < 8'hFF)
        timeout_counter <= timeout_counter + 8'd1;
      else
        timeout_error <= 1'b1;
    end else if (reset_active && reset_ack) begin
      reset_active <= 1'b0;
    end
  end
endmodule