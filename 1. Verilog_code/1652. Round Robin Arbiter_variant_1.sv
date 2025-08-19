//SystemVerilog
module round_robin_arbiter #(parameter WIDTH = 8) (
  input wire clock, reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt,
  output reg active
);

  reg [WIDTH-1:0] pointer;
  wire [WIDTH-1:0] req_rotated;
  wire [WIDTH-1:0] gnt_rotated;
  wire [WIDTH-1:0] mask;
  wire [WIDTH-1:0] masked_req;
  wire [WIDTH-1:0] masked_gnt;
  
  // Rotate request vector based on pointer
  assign req_rotated = {req[WIDTH-1:0], req[WIDTH-1:0]} >> pointer;
  
  // Generate mask for priority encoding
  assign mask = ~((1 << WIDTH) - 1);
  
  // Apply mask to rotated requests
  assign masked_req = req_rotated & ~mask;
  
  // Priority encoder using parallel logic
  assign masked_gnt = masked_req & ~(masked_req - 1);
  
  // Rotate grant vector back
  assign gnt_rotated = masked_gnt << pointer;
  
  always @(posedge clock) begin
    if (reset) begin
      pointer <= 1;
      gnt <= 0;
      active <= 0;
    end else begin
      gnt <= gnt_rotated;
      active <= |req;
      if (|masked_gnt) begin
        pointer <= (pointer + $clog2(WIDTH)) % WIDTH;
      end
    end
  end

endmodule