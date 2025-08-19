//SystemVerilog
module round_robin_arbiter #(parameter WIDTH = 8) (
  input wire clock, reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt,
  output reg active
);

  wire [WIDTH-1:0] next_pointer;
  wire [WIDTH-1:0] next_gnt;
  wire next_active;
  reg [WIDTH-1:0] pointer;
  reg [WIDTH-1:0] req_pipe;
  reg [WIDTH-1:0] pointer_pipe;

  pointer_update #(.WIDTH(WIDTH)) pointer_inst (
    .clock(clock),
    .reset(reset),
    .req(req_pipe),
    .pointer(pointer_pipe),
    .next_pointer(next_pointer)
  );

  grant_generator #(.WIDTH(WIDTH)) grant_inst (
    .clock(clock),
    .reset(reset),
    .req(req_pipe),
    .pointer(pointer_pipe),
    .next_pointer(next_pointer),
    .gnt(gnt),
    .next_gnt(next_gnt),
    .active(active),
    .next_active(next_active)
  );

  always @(posedge clock) begin
    if (reset) begin
      pointer <= 1;
      gnt <= 0;
      active <= 0;
      req_pipe <= 0;
      pointer_pipe <= 1;
    end else begin
      pointer <= next_pointer;
      gnt <= next_gnt;
      active <= next_active;
      req_pipe <= req;
      pointer_pipe <= pointer;
    end
  end

endmodule

module pointer_update #(parameter WIDTH = 8) (
  input wire clock,
  input wire reset,
  input wire [WIDTH-1:0] req,
  input wire [WIDTH-1:0] pointer,
  output reg [WIDTH-1:0] next_pointer
);

  integer j;
  reg found;
  reg [WIDTH-1:0] req_pipe;
  reg [WIDTH-1:0] pointer_pipe;

  always @(posedge clock) begin
    if (reset) begin
      req_pipe <= 0;
      pointer_pipe <= 1;
    end else begin
      req_pipe <= req;
      pointer_pipe <= pointer;
    end
  end

  always @(*) begin
    next_pointer = pointer_pipe;
    found = 0;
    for (j = 0; j < WIDTH; j = j + 1) begin
      if (!found && req_pipe[(j + pointer_pipe) % WIDTH]) begin
        next_pointer = (j + pointer_pipe + 1) % WIDTH;
        found = 1;
      end
    end
  end

endmodule

module grant_generator #(parameter WIDTH = 8) (
  input wire clock,
  input wire reset,
  input wire [WIDTH-1:0] req,
  input wire [WIDTH-1:0] pointer,
  input wire [WIDTH-1:0] next_pointer,
  input wire [WIDTH-1:0] gnt,
  output reg [WIDTH-1:0] next_gnt,
  input wire active,
  output reg next_active
);

  integer j;
  reg found;
  reg [WIDTH-1:0] req_pipe;
  reg [WIDTH-1:0] pointer_pipe;
  reg [WIDTH-1:0] next_pointer_pipe;

  always @(posedge clock) begin
    if (reset) begin
      req_pipe <= 0;
      pointer_pipe <= 1;
      next_pointer_pipe <= 1;
    end else begin
      req_pipe <= req;
      pointer_pipe <= pointer;
      next_pointer_pipe <= next_pointer;
    end
  end

  always @(*) begin
    next_gnt = 0;
    next_active = |req_pipe;
    found = 0;
    for (j = 0; j < WIDTH; j = j + 1) begin
      if (!found && req_pipe[(j + pointer_pipe) % WIDTH]) begin
        next_gnt[(j + pointer_pipe) % WIDTH] = 1'b1;
        found = 1;
      end
    end
  end

endmodule