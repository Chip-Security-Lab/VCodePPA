//SystemVerilog
module scoreboard_arbiter(
  input wire clk, reset,
  input wire [3:0] requests,
  output reg [3:0] grants
);
  reg [7:0] scores [3:0];
  reg [1:0] highest_idx;
  reg [1:0] highest_idx_pipe;
  reg [3:0] requests_pipe;
  reg comp_valid;
  
  // Pipeline registers for comparison results
  reg [1:0] comp_stage1;
  reg comp_12_gt_0, comp_2_gt_1;
  reg comp_3_gt_0, comp_3_gt_1, comp_3_gt_2;
  
  // Score update logic
  always @(posedge clk) begin
    if (reset) begin
      scores[0] <= 8'h80;
      scores[1] <= 8'h80;
      scores[2] <= 8'h80;
      scores[3] <= 8'h80;
      highest_idx <= 2'b00;
      highest_idx_pipe <= 2'b00;
      grants <= 4'h0;
      requests_pipe <= 4'h0;
      comp_valid <= 1'b0;
      comp_stage1 <= 2'd0;
      comp_12_gt_0 <= 1'b0;
      comp_2_gt_1 <= 1'b0;
      comp_3_gt_0 <= 1'b0;
      comp_3_gt_1 <= 1'b0;
      comp_3_gt_2 <= 1'b0;
    end else begin
      // Update scores based on activity - 展开的for循环
      // Index 0
      if (requests[0]) begin
        if (scores[0] < 8'hFF) scores[0] <= scores[0] + 1;
      end else begin
        if (scores[0] > 0) scores[0] <= scores[0] - 1;
      end
      
      // Index 1
      if (requests[1]) begin
        if (scores[1] < 8'hFF) scores[1] <= scores[1] + 1;
      end else begin
        if (scores[1] > 0) scores[1] <= scores[1] - 1;
      end
      
      // Index 2
      if (requests[2]) begin
        if (scores[2] < 8'hFF) scores[2] <= scores[2] + 1;
      end else begin
        if (scores[2] > 0) scores[2] <= scores[2] - 1;
      end
      
      // Index 3
      if (requests[3]) begin
        if (scores[3] < 8'hFF) scores[3] <= scores[3] + 1;
      end else begin
        if (scores[3] > 0) scores[3] <= scores[3] - 1;
      end
      
      // First pipeline stage - compute basic comparisons
      comp_12_gt_0 <= requests[1] && (scores[1] > scores[0]);
      comp_2_gt_1 <= scores[2] > scores[1];
      comp_3_gt_0 <= scores[3] > scores[0];
      comp_3_gt_1 <= scores[3] > scores[1];
      comp_3_gt_2 <= scores[3] > scores[2];
      requests_pipe <= requests;
      
      // Second pipeline stage - determine highest index
      if (comp_12_gt_0) begin
        comp_stage1 <= 2'd1;
      end else begin
        comp_stage1 <= 2'd0;
      end
      
      // Third pipeline stage - final comparison and selection
      highest_idx <= comp_stage1;
      
      if (requests_pipe[2] && (
          (comp_stage1 == 2'd0 && scores[2] > scores[0]) || 
          (comp_stage1 == 2'd1 && comp_2_gt_1)
         )) begin
        highest_idx <= 2'd2;
      end
      
      if (requests_pipe[3] && (
          (comp_stage1 == 2'd0 && comp_3_gt_0) || 
          (comp_stage1 == 2'd1 && comp_3_gt_1) ||
          (highest_idx == 2'd2 && comp_3_gt_2)
         )) begin
        highest_idx <= 2'd3;
      end
      
      highest_idx_pipe <= highest_idx;
      comp_valid <= |requests_pipe;
      
      // Generate grant
      grants <= 4'h0;
      if (comp_valid) begin
        case (highest_idx_pipe)
          2'd0: grants[0] <= 1'b1;
          2'd1: grants[1] <= 1'b1;
          2'd2: grants[2] <= 1'b1;
          2'd3: grants[3] <= 1'b1;
        endcase
        scores[highest_idx_pipe] <= scores[highest_idx_pipe] >> 1; // Reduce priority after grant
      end
    end
  end
endmodule