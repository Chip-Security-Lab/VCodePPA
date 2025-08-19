module round_robin_intr_ctrl #(parameter WIDTH=4)(
  input wire clock, reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] grant,
  output reg active
);
  reg [WIDTH-1:0] pointer;
  wire [2*WIDTH-1:0] double_req, double_grant;
  
  assign double_req = {req, req};
  assign double_grant = double_req & ~((double_req - {{(WIDTH){1'b0}}, pointer}) | {{(WIDTH){1'b0}}, pointer});
  
  always @(posedge clock) begin
    if (reset) begin
      pointer <= {{(WIDTH-1){1'b0}}, 1'b1};
      grant <= {WIDTH{1'b0}}; active <= 1'b0;
    end else if (|req) begin
      grant <= double_grant[WIDTH-1:0] | double_grant[2*WIDTH-1:WIDTH];
      pointer <= {grant[WIDTH-2:0], grant[WIDTH-1]};
      active <= 1'b1;
    end else active <= 1'b0;
  end
endmodule