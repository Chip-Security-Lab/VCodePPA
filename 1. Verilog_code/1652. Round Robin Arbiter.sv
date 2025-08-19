module round_robin_arbiter #(parameter WIDTH = 8) (
  input wire clock, reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt,
  output reg active
);
  reg [WIDTH-1:0] pointer;
  integer j;
  reg found;
  always @(posedge clock) begin
    if (reset) begin
      pointer <= 1; gnt <= 0; active <= 0;
    end else begin
      gnt <= 0; active <= |req;
      found = 0;
      for (j = 0; j < WIDTH; j = j + 1) begin
        if (!found && req[(j + pointer) % WIDTH]) begin
          gnt[(j + pointer) % WIDTH] <= 1'b1;
          pointer <= (j + pointer + 1) % WIDTH;
          found = 1;
        end
      end
    end
  end
endmodule