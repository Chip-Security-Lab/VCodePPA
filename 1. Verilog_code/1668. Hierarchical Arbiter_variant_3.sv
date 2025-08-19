//SystemVerilog
module hierarchical_arbiter(
  input clock, reset,
  input [7:0] requests,
  output reg [7:0] grants
);

  // Stage 1 signals
  reg [7:0] requests_stage1;
  wire [1:0] level1_req_stage1;
  reg [1:0] level1_grant_stage1;
  
  // Stage 2 signals
  reg [1:0] level1_grant_stage2;
  reg [7:0] requests_stage2;
  reg [7:0] grants_stage2;

  // Pre-compute level 1 requests
  wire level1_req_low = |requests_stage1[3:0];
  wire level1_req_high = |requests_stage1[7:4];
  assign level1_req_stage1 = {level1_req_high, level1_req_low};

  // Optimized grant computation
  wire [1:0] level1_grant_next = level1_req_stage1 & ~(level1_req_stage1 - 1);

  // Stage 1 pipeline register
  always @(posedge clock) begin
    if (reset) begin
      requests_stage1 <= 8'b0;
      level1_grant_stage1 <= 2'b0;
    end else begin
      requests_stage1 <= requests;
      level1_grant_stage1 <= level1_grant_next;
    end
  end

  // Pre-compute level 2 grants
  wire [3:0] grants_low = level1_grant_stage1[0] ? requests_stage1[3:0] : 4'b0;
  wire [3:0] grants_high = level1_grant_stage1[1] ? requests_stage1[7:4] : 4'b0;

  // Stage 2 pipeline register
  always @(posedge clock) begin
    if (reset) begin
      level1_grant_stage2 <= 2'b0;
      requests_stage2 <= 8'b0;
      grants_stage2 <= 8'b0;
    end else begin
      level1_grant_stage2 <= level1_grant_stage1;
      requests_stage2 <= requests_stage1;
      grants_stage2 <= {grants_high, grants_low};
    end
  end

  // Output stage
  always @(posedge clock) begin
    if (reset) begin
      grants <= 8'b0;
    end else begin
      grants <= grants_stage2;
    end
  end

endmodule