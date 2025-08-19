module round_robin_arbiter #(parameter WIDTH=4) (
  input wire clock, reset,
  input wire [WIDTH-1:0] request,
  output reg [WIDTH-1:0] grant
);
  reg [WIDTH-1:0] mask, nxt_mask;
  wire [WIDTH-1:0] masked_req = request & ~mask;
  
  always @(*) begin
    grant = 0;
    if (|masked_req) begin
      casez(masked_req)
        4'b???1: grant = 4'b0001;
        4'b??10: grant = 4'b0010;
        4'b?100: grant = 4'b0100;
        4'b1000: grant = 4'b1000;
      endcase
      nxt_mask = {grant[WIDTH-2:0], grant[WIDTH-1]};
    end else if (|request) begin
      casez(request)
        4'b???1: grant = 4'b0001;
        4'b??10: grant = 4'b0010;
        4'b?100: grant = 4'b0100;
        4'b1000: grant = 4'b1000;
      endcase
      nxt_mask = {grant[WIDTH-2:0], grant[WIDTH-1]};
    end else nxt_mask = mask;
  end
  always @(posedge clock) if (reset) mask <= 0; else mask <= nxt_mask;
endmodule