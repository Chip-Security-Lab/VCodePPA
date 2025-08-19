module priority_reset(
  input clk, global_rst, subsystem_rst, local_rst,
  input [7:0] data_in,
  output reg [7:0] data_out
);
  always @(posedge clk) begin
    if (global_rst)
      data_out <= 8'h00;
    else if (subsystem_rst)
      data_out <= 8'h01;
    else if (local_rst)
      data_out <= 8'h02;
    else
      data_out <= data_in;
  end
endmodule