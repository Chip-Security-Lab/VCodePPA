module reset_event_counter (
  input wire clk,
  input wire reset_n,
  output reg [7:0] reset_count
);
  always @(posedge clk) begin
    if (!reset_n)
      reset_count <= reset_count + 1;
  end
endmodule
