module memory_sync_reset #(parameter DEPTH = 8, WIDTH = 8)(
  input clk, reset,
  input [WIDTH-1:0] data_in,
  input [$clog2(DEPTH)-1:0] addr,
  input write_en,
  output reg [WIDTH-1:0] data_out
);
  reg [WIDTH-1:0] mem [0:DEPTH-1];
  integer i;
  
  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < DEPTH; i = i + 1)
        mem[i] <= 0;
      data_out <= 0;
    end else if (write_en)
      mem[addr] <= data_in;
    else
      data_out <= mem[addr];
  end
endmodule
