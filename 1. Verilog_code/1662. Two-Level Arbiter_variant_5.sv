//SystemVerilog
module two_level_arbiter(
  input clock, reset,
  input [1:0] group_sel,
  input [7:0] requests,
  output reg [7:0] grants
);

  // Stage 1: Request preprocessing
  reg [7:0] requests_stage1;
  reg [1:0] group_sel_stage1;
  
  // Stage 2: Group request calculation
  reg [1:0] group_reqs_stage2;
  
  // Stage 3: Group arbitration
  reg [1:0] group_grants_stage3;
  
  // Stage 4: Within-group arbitration preparation
  reg [3:0] group0_requests_stage4;
  reg [3:0] group1_requests_stage4;
  reg [1:0] group_grants_stage4;
  
  // Stage 5: Within-group arbitration
  reg [3:0] group0_grants_stage5;
  reg [3:0] group1_grants_stage5;
  
  // Stage 6: Final grant combination
  reg [7:0] grants_stage6;

  // Stage 1: Register inputs
  always @(posedge clock) begin
    if (reset) begin
      requests_stage1 <= 8'b0;
      group_sel_stage1 <= 2'b0;
    end else begin
      requests_stage1 <= requests;
      group_sel_stage1 <= group_sel;
    end
  end

  // Stage 2: Calculate group requests
  always @(posedge clock) begin
    if (reset) begin
      group_reqs_stage2 <= 2'b0;
    end else begin
      group_reqs_stage2[0] <= |requests_stage1[3:0];
      group_reqs_stage2[1] <= |requests_stage1[7:4];
    end
  end

  // Stage 3: Group arbitration
  always @(posedge clock) begin
    if (reset) begin
      group_grants_stage3 <= 2'b0;
    end else begin
      group_grants_stage3 <= 2'b0;
      if (group_reqs_stage2[0] && group_sel_stage1[0]) 
        group_grants_stage3[0] <= 1'b1;
      else if (group_reqs_stage2[1] && group_sel_stage1[1])
        group_grants_stage3[1] <= 1'b1;
    end
  end

  // Stage 4: Prepare for within-group arbitration
  always @(posedge clock) begin
    if (reset) begin
      group0_requests_stage4 <= 4'b0;
      group1_requests_stage4 <= 4'b0;
      group_grants_stage4 <= 2'b0;
    end else begin
      group0_requests_stage4 <= requests_stage1[3:0];
      group1_requests_stage4 <= requests_stage1[7:4];
      group_grants_stage4 <= group_grants_stage3;
    end
  end

  // Stage 5: Within-group arbitration
  always @(posedge clock) begin
    if (reset) begin
      group0_grants_stage5 <= 4'b0;
      group1_grants_stage5 <= 4'b0;
    end else begin
      group0_grants_stage5 <= 4'b0;
      group1_grants_stage5 <= 4'b0;
      
      if (group_grants_stage4[0]) begin
        // Priority encoding for group 0
        if (group0_requests_stage4[0]) group0_grants_stage5[0] <= 1'b1;
        else if (group0_requests_stage4[1]) group0_grants_stage5[1] <= 1'b1;
        else if (group0_requests_stage4[2]) group0_grants_stage5[2] <= 1'b1;
        else if (group0_requests_stage4[3]) group0_grants_stage5[3] <= 1'b1;
      end
      
      if (group_grants_stage4[1]) begin
        // Priority encoding for group 1
        if (group1_requests_stage4[0]) group1_grants_stage5[0] <= 1'b1;
        else if (group1_requests_stage4[1]) group1_grants_stage5[1] <= 1'b1;
        else if (group1_requests_stage4[2]) group1_grants_stage5[2] <= 1'b1;
        else if (group1_requests_stage4[3]) group1_grants_stage5[3] <= 1'b1;
      end
    end
  end

  // Stage 6: Combine final grants
  always @(posedge clock) begin
    if (reset) begin
      grants_stage6 <= 8'b0;
    end else begin
      grants_stage6 <= {group1_grants_stage5, group0_grants_stage5};
    end
  end

  // Output assignment
  always @(posedge clock) begin
    if (reset) begin
      grants <= 8'b0;
    end else begin
      grants <= grants_stage6;
    end
  end

endmodule