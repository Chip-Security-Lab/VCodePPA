//SystemVerilog
module prog_mask_intr_ctrl(
  input wire CLK, nRST,
  input wire [7:0] INTR, MASK,
  input wire UPDATE_MASK,
  output reg [2:0] ID,
  output reg VALID
);
  // Stage 1 registers
  reg [7:0] mask_reg;
  reg [7:0] intr_stage1;
  reg update_mask_stage1;
  
  // Stage 2 registers
  reg [7:0] masked_intr_stage2;
  reg valid_stage2;
  reg [2:0] id_stage2;
  
  // Pipeline stage 1: Input registration and mask application
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      mask_reg <= 8'hFF;
      intr_stage1 <= 8'h0;
      update_mask_stage1 <= 1'b0;
    end else begin
      intr_stage1 <= INTR;
      update_mask_stage1 <= UPDATE_MASK;
      
      if (update_mask_stage1)
        mask_reg <= MASK;
    end
  end
  
  // Combinational logic for priority encoding
  function [3:0] get_priority;
    input [7:0] masked_intr;
    begin
      if (masked_intr[0])      get_priority = {1'b1, 3'd0};
      else if (masked_intr[1]) get_priority = {1'b1, 3'd1};
      else if (masked_intr[2]) get_priority = {1'b1, 3'd2};
      else if (masked_intr[3]) get_priority = {1'b1, 3'd3};
      else if (masked_intr[4]) get_priority = {1'b1, 3'd4};
      else if (masked_intr[5]) get_priority = {1'b1, 3'd5};
      else if (masked_intr[6]) get_priority = {1'b1, 3'd6};
      else if (masked_intr[7]) get_priority = {1'b1, 3'd7};
      else                     get_priority = {1'b0, 3'd0};
    end
  endfunction
  
  // Pipeline stage 2: Masking and priority encoding
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      masked_intr_stage2 <= 8'h0;
      valid_stage2 <= 1'b0;
      id_stage2 <= 3'd0;
    end else begin
      // Apply mask and store in stage 2
      masked_intr_stage2 <= intr_stage1 & mask_reg;
      
      // Determine valid and ID based on priority in one step
      {valid_stage2, id_stage2} <= get_priority(intr_stage1 & mask_reg);
    end
  end
  
  // Final output stage
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      ID <= 3'd0;
      VALID <= 1'b0;
    end else begin
      ID <= id_stage2;
      VALID <= valid_stage2;
    end
  end
  
endmodule