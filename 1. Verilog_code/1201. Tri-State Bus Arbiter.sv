module tristate_bus_arbiter(
  input wire clk, reset,
  input wire [3:0] req,
  output wire [3:0] grant,
  inout wire [7:0] data_bus,
  input wire [7:0] data_in [3:0],
  output wire [7:0] data_out
);
  reg [3:0] grant_r;
  reg [1:0] current;
  
  assign grant = grant_r;
  assign data_bus = grant_r[0] ? data_in[0] : 
                   (grant_r[1] ? data_in[1] : 
                   (grant_r[2] ? data_in[2] : 
                   (grant_r[3] ? data_in[3] : 8'bz)));
  assign data_out = data_bus;
  
  always @(posedge clk) begin
    if (reset) begin
      grant_r <= 4'h0;
      current <= 2'b00;
    end else begin
      if (req[current]) grant_r <= (4'h1 << current);
      else grant_r <= 4'h0;
      current <= current + 1;
    end
  end
endmodule