//SystemVerilog
module round_robin_pointer #(parameter WIDTH = 8) (
  input wire clock,
  input wire reset,
  input wire update,
  input wire [WIDTH-1:0] current_pos,
  output reg [WIDTH-1:0] next_pos
);
  always @(posedge clock) begin
    if (reset) begin
      next_pos <= 1;
    end else if (update) begin
      next_pos <= (current_pos + 1) % WIDTH;
    end
  end
endmodule

module request_processor #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] req,
  input wire [WIDTH-1:0] pointer,
  output reg [WIDTH-1:0] gnt,
  output reg found
);
  integer j;
  always @(*) begin
    gnt = 0;
    found = 0;
    for (j = 0; j < WIDTH; j = j + 1) begin
      if (!found && req[(j + pointer) % WIDTH]) begin
        gnt[(j + pointer) % WIDTH] = 1'b1;
        found = 1;
      end
    end
  end
endmodule

module round_robin_arbiter #(parameter WIDTH = 8) (
  input wire clock,
  input wire reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt,
  output reg active
);
  wire [WIDTH-1:0] next_pointer;
  wire found;
  wire [WIDTH-1:0] internal_gnt;
  reg [WIDTH-1:0] pointer;

  round_robin_pointer #(.WIDTH(WIDTH)) pointer_unit (
    .clock(clock),
    .reset(reset),
    .update(found),
    .current_pos(pointer),
    .next_pos(next_pointer)
  );

  request_processor #(.WIDTH(WIDTH)) processor (
    .req(req),
    .pointer(pointer),
    .gnt(internal_gnt),
    .found(found)
  );

  always @(posedge clock) begin
    if (reset) begin
      pointer <= 1;
      gnt <= 0;
      active <= 0;
    end else begin
      pointer <= next_pointer;
      gnt <= internal_gnt;
      active <= |req;
    end
  end
endmodule