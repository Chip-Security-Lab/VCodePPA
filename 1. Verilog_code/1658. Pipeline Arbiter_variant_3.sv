//SystemVerilog
module pipeline_arbiter(
  input wire clk, async_reset_n,
  input wire [3:0] request,
  input wire pipe_ready,
  output reg [3:0] grant,
  output reg valid
);
  reg [3:0] req_stage1, req_stage2;
  reg [1:0] state, next_state;
  reg [3:0] grant_pre;
  reg valid_pre;
  
  // Pre-compute request flags to reduce critical path
  wire req0, req1, req2, req3;
  assign req0 = req_stage2[0];
  assign req1 = req_stage2[1];
  assign req2 = req_stage2[2];
  assign req3 = req_stage2[3];
  
  // Optimize grant logic with balanced paths
  wire [3:0] grant_next;
  assign grant_next[0] = pipe_ready & req0;
  assign grant_next[1] = pipe_ready & req1 & ~req0;
  assign grant_next[2] = pipe_ready & req2 & ~req0 & ~req1;
  assign grant_next[3] = pipe_ready & req3 & ~req0 & ~req1 & ~req2;
  
  // Optimize valid logic
  wire valid_next;
  assign valid_next = pipe_ready & (req0 | req1 | req2 | req3);
  
  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      state <= 2'b00; 
      req_stage1 <= 4'b0; 
      req_stage2 <= 4'b0; 
      grant_pre <= 4'b0;
      valid_pre <= 1'b0;
      grant <= 4'b0;
      valid <= 1'b0;
    end else begin
      state <= next_state;
      req_stage1 <= request;
      req_stage2 <= req_stage1;
      
      // Stage 1: Calculate grant and valid with optimized logic
      grant_pre <= grant_next;
      valid_pre <= valid_next;
      
      // Stage 2: Register outputs
      grant <= grant_pre;
      valid <= valid_pre;
    end
  end
endmodule