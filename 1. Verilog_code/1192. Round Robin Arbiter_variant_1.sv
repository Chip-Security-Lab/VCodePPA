//SystemVerilog
//IEEE 1364-2005
module round_robin_arbiter #(parameter WIDTH=4) (
  input wire clock, reset,
  input wire [WIDTH-1:0] request,
  input wire ready_in,
  output wire [WIDTH-1:0] grant,
  output wire valid_out
);
  // Stage 1: Request processing
  reg [WIDTH-1:0] mask;
  reg [WIDTH-1:0] request_stage1;
  reg [WIDTH-1:0] masked_req_stage1;
  reg valid_stage1;
  
  // Stage 2: Priority encoding - Split to reduce critical path
  reg [WIDTH-1:0] masked_req_stage2;
  reg [WIDTH-1:0] request_stage2;
  reg valid_stage2;
  
  // New intermediate pipeline registers for priority encoding
  reg [WIDTH-1:0] masked_grant_pipe;
  reg [WIDTH-1:0] raw_grant_pipe;
  reg use_masked_pipe;
  reg valid_stage2_pipe;
  
  // Stage 3: Grant generation
  reg [WIDTH-1:0] grant_stage3;
  reg valid_stage3;
  
  // Pipeline control signals
  wire pipeline_ready = ready_in || !valid_stage3;
  wire pipeline_enable = pipeline_ready;

  // Stage 1: Mask request and register
  always @(posedge clock) begin
    if (reset) begin
      request_stage1 <= 0;
      masked_req_stage1 <= 0;
      valid_stage1 <= 0;
    end else if (pipeline_enable) begin
      request_stage1 <= request;
      masked_req_stage1 <= request & ~mask;
      valid_stage1 <= |request;  // Only valid if there's a request
    end
  end
  
  // Stage 2: Register request and masked request for priority encoding
  always @(posedge clock) begin
    if (reset) begin
      masked_req_stage2 <= 0;
      request_stage2 <= 0;
      valid_stage2 <= 0;
    end else if (pipeline_enable) begin
      masked_req_stage2 <= masked_req_stage1;
      request_stage2 <= request_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Split priority encoder computation to intermediate wires
  wire [WIDTH-1:0] masked_grant_part;
  wire [WIDTH-1:0] raw_grant_part;
  wire use_masked = |masked_req_stage2;
  
  // First part of priority encoding - simpler bit-by-bit logic
  assign masked_grant_part[0] = masked_req_stage2[0];
  assign masked_grant_part[1] = masked_req_stage2[1] & ~masked_req_stage2[0];
  assign masked_grant_part[2] = masked_req_stage2[2] & ~masked_req_stage2[1] & ~masked_req_stage2[0];
  assign masked_grant_part[3] = masked_req_stage2[3] & ~masked_req_stage2[2] & ~masked_req_stage2[1] & ~masked_req_stage2[0];
  
  // First part of raw priority encoding
  assign raw_grant_part[0] = request_stage2[0];
  assign raw_grant_part[1] = request_stage2[1] & ~request_stage2[0];
  assign raw_grant_part[2] = request_stage2[2] & ~request_stage2[1] & ~request_stage2[0];
  assign raw_grant_part[3] = request_stage2[3] & ~request_stage2[2] & ~request_stage2[1] & ~request_stage2[0];
  
  // Pipeline register for priority encoder outputs - CRITICAL PATH CUT
  always @(posedge clock) begin
    if (reset) begin
      masked_grant_pipe <= 0;
      raw_grant_pipe <= 0;
      use_masked_pipe <= 0;
      valid_stage2_pipe <= 0;
    end else if (pipeline_enable) begin
      masked_grant_pipe <= masked_grant_part;
      raw_grant_pipe <= raw_grant_part;
      use_masked_pipe <= use_masked;
      valid_stage2_pipe <= valid_stage2;
    end
  end
  
  // Stage 3: Generate grant - now using pipelined values
  always @(posedge clock) begin
    if (reset) begin
      grant_stage3 <= 0;
      valid_stage3 <= 0;
    end else if (pipeline_enable) begin
      valid_stage3 <= valid_stage2_pipe;
      
      if (valid_stage2_pipe) begin
        grant_stage3 <= use_masked_pipe ? masked_grant_pipe : raw_grant_pipe;
      end else begin
        grant_stage3 <= 0;
      end
    end
  end
  
  // Pipeline registers for mask calculation
  reg [WIDTH-1:0] grant_for_mask;
  reg update_mask;
  
  // Register grant for mask calculation to break critical path
  always @(posedge clock) begin
    if (reset) begin
      grant_for_mask <= 0;
      update_mask <= 0;
    end else begin
      grant_for_mask <= grant_stage3;
      update_mask <= valid_stage3 && ready_in && |grant_stage3;
    end
  end
  
  // Mask update logic - now with registered inputs
  always @(posedge clock) begin
    if (reset) begin
      mask <= 0;
    end else if (update_mask) begin
      // Create mask for next arbitration cycle
      if (grant_for_mask[WIDTH-1])
        mask <= {{WIDTH-1{1'b0}}, 1'b1}; // Wrap around to position 0
      else
        mask <= {grant_for_mask[WIDTH-2:0], 2'b01}; // Optimized shift calculation
    end
  end
  
  // Output assignments
  assign grant = grant_stage3;
  assign valid_out = valid_stage3;
  
endmodule