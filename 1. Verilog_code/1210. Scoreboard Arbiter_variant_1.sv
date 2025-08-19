//SystemVerilog
module scoreboard_arbiter(
  input wire clk, reset,
  input wire [3:0] requests,
  output reg [3:0] grants
);
  // Score storage registers for each pipeline stage
  reg [7:0] scores [3:0];
  reg [7:0] scores_stage1 [3:0];
  reg [7:0] scores_stage2 [3:0];
  reg [7:0] scores_stage3 [3:0];
  
  // Request buffering for multi-stage pipeline
  reg [3:0] requests_stage0;
  reg [3:0] requests_stage1;
  reg [3:0] requests_stage2;
  reg [3:0] requests_stage3;
  
  // Index tracking through pipeline stages
  reg [1:0] highest_idx_stage1;
  reg [1:0] highest_idx_stage2;
  reg [1:0] highest_idx_stage3;
  reg [1:0] highest_idx_final;
  
  // Comparison results between stages
  reg [1:0] comp_idx01_stage1;
  reg [1:0] comp_idx23_stage1;
  reg comp_valid01_stage1;
  reg comp_valid23_stage1;
  
  reg [7:0] highest_score_stage1;
  reg [7:0] highest_score_stage2;
  
  // Pipeline control signals
  reg pipeline_valid_stage1;
  reg pipeline_valid_stage2;
  reg pipeline_valid_stage3;
  
  integer i;
  
  always @(posedge clk) begin
    if (reset) begin
      // Reset all pipeline registers
      for (i = 0; i < 4; i = i + 1) begin
        scores[i] <= 8'h80;
        scores_stage1[i] <= 8'h80;
        scores_stage2[i] <= 8'h80;
        scores_stage3[i] <= 8'h80;
      end
      
      requests_stage0 <= 4'h0;
      requests_stage1 <= 4'h0;
      requests_stage2 <= 4'h0;
      requests_stage3 <= 4'h0;
      
      highest_idx_stage1 <= 2'b00;
      highest_idx_stage2 <= 2'b00;
      highest_idx_stage3 <= 2'b00;
      highest_idx_final <= 2'b00;
      
      comp_idx01_stage1 <= 2'b00;
      comp_idx23_stage1 <= 2'b00;
      comp_valid01_stage1 <= 1'b0;
      comp_valid23_stage1 <= 1'b0;
      
      highest_score_stage1 <= 8'h00;
      highest_score_stage2 <= 8'h00;
      
      pipeline_valid_stage1 <= 1'b0;
      pipeline_valid_stage2 <= 1'b0;
      pipeline_valid_stage3 <= 1'b0;
      
      grants <= 4'h0;
    end 
    else begin
      // Stage 0: Input buffering and score updates
      requests_stage0 <= requests;
      
      // Update scores based on activity - split to reduce logic depth
      for (i = 0; i < 4; i = i + 1) begin
        if (requests_stage0[i]) begin
          if (scores[i] < 8'hFF) scores[i] <= scores[i] + 1;
        end else begin
          if (scores[i] > 0) scores[i] <= scores[i] - 1;
        end
      end
      
      // Buffer scores for stage 1
      for (i = 0; i < 4; i = i + 1) begin
        scores_stage1[i] <= scores[i];
      end
      requests_stage1 <= requests_stage0;
      pipeline_valid_stage1 <= 1'b1;
      
      // Stage 1: Initial comparisons of pairs (0 vs 1) and (2 vs 3)
      if (pipeline_valid_stage1) begin
        // Compare 0 vs 1
        if (requests_stage1[0] && (!requests_stage1[1] || scores_stage1[0] >= scores_stage1[1])) begin
          comp_idx01_stage1 <= 2'b00;
          comp_valid01_stage1 <= requests_stage1[0];
          highest_score_stage1 <= scores_stage1[0];
        end else begin
          comp_idx01_stage1 <= 2'b01;
          comp_valid01_stage1 <= requests_stage1[1];
          highest_score_stage1 <= scores_stage1[1];
        end
        
        // Compare 2 vs 3
        if (requests_stage1[2] && (!requests_stage1[3] || scores_stage1[2] >= scores_stage1[3])) begin
          comp_idx23_stage1 <= 2'b10;
          comp_valid23_stage1 <= requests_stage1[2];
          highest_score_stage2 <= scores_stage1[2];
        end else begin
          comp_idx23_stage1 <= 2'b11;
          comp_valid23_stage1 <= requests_stage1[3];
          highest_score_stage2 <= scores_stage1[3];
        end
        
        // Forward through pipeline
        requests_stage2 <= requests_stage1;
        for (i = 0; i < 4; i = i + 1) begin
          scores_stage2[i] <= scores_stage1[i];
        end
        pipeline_valid_stage2 <= pipeline_valid_stage1;
      end
      
      // Stage 2: Compare the winners from stage 1
      if (pipeline_valid_stage2) begin
        if (comp_valid01_stage1 && (!comp_valid23_stage1 || highest_score_stage1 >= highest_score_stage2)) begin
          highest_idx_stage2 <= comp_idx01_stage1;
        end else begin
          highest_idx_stage2 <= comp_idx23_stage1;
        end
        
        // Forward through pipeline
        highest_idx_stage3 <= highest_idx_stage2;
        requests_stage3 <= requests_stage2;
        for (i = 0; i < 4; i = i + 1) begin
          scores_stage3[i] <= scores_stage2[i];
        end
        pipeline_valid_stage3 <= pipeline_valid_stage2;
      end
      
      // Stage 3: Generate grant and update scores
      if (pipeline_valid_stage3) begin
        highest_idx_final <= highest_idx_stage3;
        
        // Generate grant
        grants <= 4'h0;
        if (|requests_stage3) begin
          grants[highest_idx_stage3] <= 1'b1;
          // Reduce priority after grant
          scores[highest_idx_stage3] <= scores[highest_idx_stage3] >> 1;
        end
      end
    end
  end
endmodule