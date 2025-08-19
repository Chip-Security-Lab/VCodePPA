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
  
  // Pipeline stage 1: Register inputs and compute masked interrupts
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      mask_reg <= 8'hFF;
      intr_stage1 <= 8'h00;
      update_mask_stage1 <= 1'b0;
    end else begin
      intr_stage1 <= INTR;
      update_mask_stage1 <= UPDATE_MASK;
      
      if (UPDATE_MASK)
        mask_reg <= MASK;
    end
  end
  
  // Pipeline stage 2: Compute masked interrupts and validity
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      masked_intr_stage2 <= 8'h00;
      valid_stage2 <= 1'b0;
    end else begin
      masked_intr_stage2 <= intr_stage1 & mask_reg;
      valid_stage2 <= |(intr_stage1 & mask_reg);
    end
  end
  
  // Pipeline stage 3: Priority encoding with optimized comparator structure
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      ID <= 3'd0;
      VALID <= 1'b0;
    end else begin
      VALID <= valid_stage2;
      
      // Optimized priority encoder using binary search approach
      if (masked_intr_stage2[7:4] != 4'b0000) begin
        // Upper half has at least one bit set
        if (masked_intr_stage2[7:6] != 2'b00) begin
          // Upper quarter has at least one bit set
          ID <= masked_intr_stage2[7] ? 3'd7 : 3'd6;
        end else begin
          // Second quarter has at least one bit set
          ID <= masked_intr_stage2[5] ? 3'd5 : 3'd4;
        end
      end else begin
        // Lower half has at least one bit set
        if (masked_intr_stage2[3:2] != 2'b00) begin
          // Third quarter has at least one bit set
          ID <= masked_intr_stage2[3] ? 3'd3 : 3'd2;
        end else begin
          // Bottom quarter has at least one bit set
          ID <= masked_intr_stage2[1] ? 3'd1 : 3'd0;
        end
      end
    end
  end
endmodule