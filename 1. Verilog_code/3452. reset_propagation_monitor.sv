module reset_propagation_monitor (
  input wire clk,
  input wire reset_src,
  input wire [3:0] reset_dst,
  output reg propagation_error
);
  reg reset_src_d;
  reg [7:0] timeout;
  reg checking;

  always @(posedge clk) begin
    reset_src_d <= reset_src;
    if (reset_src && !reset_src_d) begin
      checking <= 1'b1;
      timeout <= 8'd0;
      propagation_error <= 1'b0;
    end else if (checking) begin
      timeout <= timeout + 1;
      if (&reset_dst)
        checking <= 1'b0;
      else if (timeout == 8'hFF) begin
        propagation_error <= 1'b1;
        checking <= 1'b0;
      end
    end
  end
endmodule

