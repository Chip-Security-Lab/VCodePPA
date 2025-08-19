//SystemVerilog
//IEEE 1364-2005 Standard
module one_hot_arbiter(
  input wire clock, clear,
  input wire enable,
  input wire [7:0] requests,
  output reg [7:0] grants
);
  // Pipeline stage 1: calculate masked_requests
  reg [7:0] priority_mask;
  reg [7:0] requests_stage1;
  reg [7:0] priority_mask_stage1;
  reg enable_stage1;
  
  // Pipeline stage 2: process masked requests
  reg [7:0] masked_requests_stage2;
  reg [7:0] requests_stage2;
  reg enable_stage2;
  reg [7:0] masked_grant_stage2;
  reg masked_valid_stage2;
  
  // Pipeline stage 3: process unmasked requests
  reg [7:0] unmasked_grant_stage3;
  reg masked_valid_stage3;
  reg [7:0] masked_grant_stage3;
  reg enable_stage3;
  
  // Pipeline stage 4: final grant selection
  reg [7:0] next_grants_stage4;
  
  // Stage 1: Register inputs and calculate masked requests
  always @(posedge clock or posedge clear) begin
    if (clear) begin
      requests_stage1 <= 8'h00;
      priority_mask_stage1 <= 8'h00;
      enable_stage1 <= 1'b0;
    end else begin
      requests_stage1 <= requests;
      priority_mask_stage1 <= priority_mask;
      enable_stage1 <= enable;
    end
  end
  
  // Stage 2: Process masked requests
  always @(posedge clock or posedge clear) begin
    if (clear) begin
      masked_requests_stage2 <= 8'h00;
      requests_stage2 <= 8'h00;
      enable_stage2 <= 1'b0;
      masked_grant_stage2 <= 8'h00;
      masked_valid_stage2 <= 1'b0;
    end else begin
      masked_requests_stage2 <= requests_stage1 & ~priority_mask_stage1;
      requests_stage2 <= requests_stage1;
      enable_stage2 <= enable_stage1;
      
      // First priority: masked requests
      masked_valid_stage2 <= |(requests_stage1 & ~priority_mask_stage1);
      if (requests_stage1[0] & ~priority_mask_stage1[0])
        masked_grant_stage2 <= 8'b00000001;
      else if (requests_stage1[1] & ~priority_mask_stage1[1])
        masked_grant_stage2 <= 8'b00000010;
      else if (requests_stage1[2] & ~priority_mask_stage1[2])
        masked_grant_stage2 <= 8'b00000100;
      else if (requests_stage1[3] & ~priority_mask_stage1[3])
        masked_grant_stage2 <= 8'b00001000;
      else if (requests_stage1[4] & ~priority_mask_stage1[4])
        masked_grant_stage2 <= 8'b00010000;
      else if (requests_stage1[5] & ~priority_mask_stage1[5])
        masked_grant_stage2 <= 8'b00100000;
      else if (requests_stage1[6] & ~priority_mask_stage1[6])
        masked_grant_stage2 <= 8'b01000000;
      else if (requests_stage1[7] & ~priority_mask_stage1[7])
        masked_grant_stage2 <= 8'b10000000;
      else
        masked_grant_stage2 <= 8'h00;
    end
  end
  
  // Stage 3: Process unmasked requests
  always @(posedge clock or posedge clear) begin
    if (clear) begin
      unmasked_grant_stage3 <= 8'h00;
      masked_valid_stage3 <= 1'b0;
      masked_grant_stage3 <= 8'h00;
      enable_stage3 <= 1'b0;
    end else begin
      masked_valid_stage3 <= masked_valid_stage2;
      masked_grant_stage3 <= masked_grant_stage2;
      enable_stage3 <= enable_stage2;
      
      // Second priority: unmasked requests
      if (requests_stage2[0])
        unmasked_grant_stage3 <= 8'b00000001;
      else if (requests_stage2[1])
        unmasked_grant_stage3 <= 8'b00000010;
      else if (requests_stage2[2])
        unmasked_grant_stage3 <= 8'b00000100;
      else if (requests_stage2[3])
        unmasked_grant_stage3 <= 8'b00001000;
      else if (requests_stage2[4])
        unmasked_grant_stage3 <= 8'b00010000;
      else if (requests_stage2[5])
        unmasked_grant_stage3 <= 8'b00100000;
      else if (requests_stage2[6])
        unmasked_grant_stage3 <= 8'b01000000;
      else if (requests_stage2[7])
        unmasked_grant_stage3 <= 8'b10000000;
      else
        unmasked_grant_stage3 <= 8'h00;
    end
  end
  
  // Stage 4: Final grant selection and priority update
  always @(posedge clock or posedge clear) begin
    if (clear) begin
      next_grants_stage4 <= 8'h00;
      grants <= 8'h00;
      priority_mask <= 8'h01;
    end else begin
      next_grants_stage4 <= masked_valid_stage3 ? masked_grant_stage3 : unmasked_grant_stage3;
      
      if (enable_stage3) begin
        grants <= next_grants_stage4;
        if (|next_grants_stage4) 
          priority_mask <= {next_grants_stage4[6:0], next_grants_stage4[7]};
      end
    end
  end
endmodule