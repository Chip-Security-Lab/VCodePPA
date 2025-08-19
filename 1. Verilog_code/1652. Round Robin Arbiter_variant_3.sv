//SystemVerilog
module round_robin_arbiter #(parameter WIDTH = 8) (
  input wire clock,
  input wire reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt,
  output reg active
);

  // Pipeline stage 1: Request capture and pointer update
  reg [WIDTH-1:0] req_stage1;
  reg [WIDTH-1:0] pointer_stage1;
  reg [WIDTH-1:0] next_pointer_stage1;
  reg active_stage1;

  // Pipeline stage 2: Priority resolution
  reg [WIDTH-1:0] req_stage2;
  reg [WIDTH-1:0] pointer_stage2;
  reg [WIDTH-1:0] gnt_stage2;
  reg [WIDTH-1:0] next_pointer_stage2;
  reg active_stage2;

  // Pipeline stage 3: Grant output
  reg [WIDTH-1:0] gnt_stage3;
  reg active_stage3;

  // Stage 1: Request capture and pointer update
  always @(posedge clock) begin
    if (reset) begin
      req_stage1 <= 0;
      pointer_stage1 <= 1;
      next_pointer_stage1 <= 1;
      active_stage1 <= 0;
    end else begin
      req_stage1 <= req;
      pointer_stage1 <= next_pointer_stage2;
      active_stage1 <= |req;
    end
  end

  // Stage 2: Priority resolution
  always @(posedge clock) begin
    if (reset) begin
      req_stage2 <= 0;
      pointer_stage2 <= 1;
      gnt_stage2 <= 0;
      next_pointer_stage2 <= 1;
      active_stage2 <= 0;
    end else begin
      req_stage2 <= req_stage1;
      pointer_stage2 <= pointer_stage1;
      active_stage2 <= active_stage1;
      
      gnt_stage2 <= 0;
      next_pointer_stage2 <= pointer_stage2;
      
      for (integer i = 0; i < WIDTH; i = i + 1) begin
        if (!(|gnt_stage2) && req_stage2[(i + pointer_stage2) % WIDTH]) begin
          gnt_stage2[(i + pointer_stage2) % WIDTH] <= 1'b1;
          next_pointer_stage2 <= (i + pointer_stage2 + 1) % WIDTH;
        end
      end
    end
  end

  // Stage 3: Grant output
  always @(posedge clock) begin
    if (reset) begin
      gnt_stage3 <= 0;
      active_stage3 <= 0;
    end else begin
      gnt_stage3 <= gnt_stage2;
      active_stage3 <= active_stage2;
    end
  end

  // Output assignments
  assign gnt = gnt_stage3;
  assign active = active_stage3;

endmodule