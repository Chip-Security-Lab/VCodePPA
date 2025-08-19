//SystemVerilog
module nested_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_req,
  input [7:0] intr_mask,
  input [15:0] intr_priority, // 2 bits per interrupt
  input ack,
  output reg [2:0] intr_id,
  output reg intr_valid
);
  // Stage 1 registers
  reg [7:0] pending_stage1;
  reg [7:0] intr_req_stage1;
  reg [7:0] intr_mask_stage1;
  reg [15:0] intr_priority_stage1;
  reg ack_stage1;
  reg [2:0] intr_id_stage1;
  reg valid_stage1;
  
  // Stage 2 registers
  reg [7:0] masked_pending_stage2;
  reg [7:0] pending_stage2;
  reg ack_stage2;
  reg [2:0] intr_id_stage2;
  reg valid_stage2;
  
  // Stage 3 registers
  reg [7:0] level0_pending_stage3;
  reg [7:0] level1_pending_stage3;
  reg [7:0] level2_pending_stage3;
  reg [7:0] level3_pending_stage3;
  reg [7:0] pending_stage3;
  reg ack_stage3;
  reg [2:0] intr_id_stage3;
  reg valid_stage3;
  
  // Stage 4 registers
  reg [7:0] level0_encoded_stage4;
  reg [7:0] level1_encoded_stage4;
  reg [7:0] level2_encoded_stage4;
  reg [7:0] level3_encoded_stage4;
  reg [7:0] pending_stage4;
  reg ack_stage4;
  reg [2:0] intr_id_stage4;
  reg valid_stage4;
  
  // Stage 5 registers
  reg [7:0] final_encoded_stage5;
  reg [1:0] selected_level_stage5;
  reg [7:0] pending_stage5;
  reg ack_stage5;
  reg [2:0] intr_id_stage5;
  reg valid_stage5;
  
  // Convert one-hot encoded value to binary
  function [2:0] onehot_to_binary;
    input [7:0] onehot;
    begin
      onehot_to_binary = 
        onehot[1] ? 3'd0 :
        onehot[2] ? 3'd1 :
        onehot[4] ? 3'd2 :
        onehot[8] ? 3'd3 :
        onehot[16] ? 3'd4 :
        onehot[32] ? 3'd5 :
        onehot[64] ? 3'd6 :
        onehot[128] ? 3'd7 : 3'd0;
    end
  endfunction
  
  // Combined pipeline stages logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset Stage 1 registers
      pending_stage1 <= 8'h0;
      intr_req_stage1 <= 8'h0;
      intr_mask_stage1 <= 8'h0;
      intr_priority_stage1 <= 16'h0;
      ack_stage1 <= 1'b0;
      intr_id_stage1 <= 3'b0;
      valid_stage1 <= 1'b0;
      
      // Reset Stage 2 registers
      masked_pending_stage2 <= 8'h0;
      pending_stage2 <= 8'h0;
      ack_stage2 <= 1'b0;
      intr_id_stage2 <= 3'b0;
      valid_stage2 <= 1'b0;
      
      // Reset Stage 3 registers
      level0_pending_stage3 <= 8'h0;
      level1_pending_stage3 <= 8'h0;
      level2_pending_stage3 <= 8'h0;
      level3_pending_stage3 <= 8'h0;
      pending_stage3 <= 8'h0;
      ack_stage3 <= 1'b0;
      intr_id_stage3 <= 3'b0;
      valid_stage3 <= 1'b0;
      
      // Reset Stage 4 registers
      level0_encoded_stage4 <= 8'h0;
      level1_encoded_stage4 <= 8'h0;
      level2_encoded_stage4 <= 8'h0;
      level3_encoded_stage4 <= 8'h0;
      pending_stage4 <= 8'h0;
      ack_stage4 <= 1'b0;
      intr_id_stage4 <= 3'b0;
      valid_stage4 <= 1'b0;
      
      // Reset Stage 5 registers
      final_encoded_stage5 <= 8'h0;
      selected_level_stage5 <= 2'b11;
      pending_stage5 <= 8'h0;
      ack_stage5 <= 1'b0;
      intr_id_stage5 <= 3'b0;
      valid_stage5 <= 1'b0;
      
      // Reset output registers
      intr_id <= 3'b0;
      intr_valid <= 1'b0;
    end 
    else begin
      // Stage 1: Register inputs and calculate basic status
      intr_req_stage1 <= intr_req;
      intr_mask_stage1 <= intr_mask;
      intr_priority_stage1 <= intr_priority;
      ack_stage1 <= ack;
      intr_id_stage1 <= intr_id;
      valid_stage1 <= intr_valid;
      
      // Update pending interrupts
      if (ack) begin
        pending_stage1 <= (pending_stage1 | (intr_req & intr_mask)) & ~(1'b1 << intr_id);
      end else begin
        pending_stage1 <= pending_stage1 | (intr_req & intr_mask);
      end
      
      // Stage 2: Calculate masked pending interrupts
      masked_pending_stage2 <= pending_stage1 & intr_mask_stage1;
      pending_stage2 <= pending_stage1;
      ack_stage2 <= ack_stage1;
      intr_id_stage2 <= intr_id_stage1;
      valid_stage2 <= valid_stage1;
      
      // Stage 3: Calculate priority level groups
      pending_stage3 <= pending_stage2;
      ack_stage3 <= ack_stage2;
      intr_id_stage3 <= intr_id_stage2;
      valid_stage3 <= valid_stage2;
      
      // Level 0 priority (lowest priority bits)
      level0_pending_stage3 <= masked_pending_stage2 & 
        (~intr_priority_stage1[15]) & (~intr_priority_stage1[13]) & (~intr_priority_stage1[11]) & 
        (~intr_priority_stage1[9]) & (~intr_priority_stage1[7]) & (~intr_priority_stage1[5]) & 
        (~intr_priority_stage1[3]) & (~intr_priority_stage1[1]);
      
      // Level 1 priority
      level1_pending_stage3 <= masked_pending_stage2 & 
        (~intr_priority_stage1[15]) & (~intr_priority_stage1[13]) & (~intr_priority_stage1[11]) & 
        (~intr_priority_stage1[9]) & (~intr_priority_stage1[7]) & (~intr_priority_stage1[5]) & 
        (~intr_priority_stage1[3]) & (intr_priority_stage1[1] | 
        ~intr_priority_stage1[14] & (~intr_priority_stage1[12]) & (~intr_priority_stage1[10]) & 
        (~intr_priority_stage1[8]) & (~intr_priority_stage1[6]) & (~intr_priority_stage1[4]) & 
        (~intr_priority_stage1[2]) & (~intr_priority_stage1[0]));
      
      // Level 2 priority
      level2_pending_stage3 <= masked_pending_stage2 & 
        ((~intr_priority_stage1[15]) & (intr_priority_stage1[14]) | 
         (~intr_priority_stage1[13]) & (intr_priority_stage1[12]) | 
         (~intr_priority_stage1[11]) & (intr_priority_stage1[10]) | 
         (~intr_priority_stage1[9]) & (intr_priority_stage1[8]) | 
         (~intr_priority_stage1[7]) & (intr_priority_stage1[6]) | 
         (~intr_priority_stage1[5]) & (intr_priority_stage1[4]) | 
         (~intr_priority_stage1[3]) & (intr_priority_stage1[2]) | 
         (~intr_priority_stage1[1]) & (intr_priority_stage1[0]));
      
      // Level 3 priority (highest priority bits)
      level3_pending_stage3 <= masked_pending_stage2 & 
        ((intr_priority_stage1[15]) & (intr_priority_stage1[14]) | 
         (intr_priority_stage1[13]) & (intr_priority_stage1[12]) | 
         (intr_priority_stage1[11]) & (intr_priority_stage1[10]) | 
         (intr_priority_stage1[9]) & (intr_priority_stage1[8]) | 
         (intr_priority_stage1[7]) & (intr_priority_stage1[6]) | 
         (intr_priority_stage1[5]) & (intr_priority_stage1[4]) | 
         (intr_priority_stage1[3]) & (intr_priority_stage1[2]) | 
         (intr_priority_stage1[1]) & (intr_priority_stage1[0]));
      
      // Stage 4: Execute priority encoding for each level
      pending_stage4 <= pending_stage3;
      ack_stage4 <= ack_stage3;
      intr_id_stage4 <= intr_id_stage3;
      valid_stage4 <= valid_stage3;
      
      // LSB-first priority encoding for level 0
      level0_encoded_stage4 <= {7'b0, level0_pending_stage3[0]} | 
                              {6'b0, level0_pending_stage3[1], 1'b0} | 
                              {5'b0, level0_pending_stage3[2], 2'b0} | 
                              {4'b0, level0_pending_stage3[3], 3'b0} | 
                              {3'b0, level0_pending_stage3[4], 4'b0} | 
                              {2'b0, level0_pending_stage3[5], 5'b0} | 
                              {1'b0, level0_pending_stage3[6], 6'b0} | 
                              {level0_pending_stage3[7], 7'b0};
      
      // LSB-first priority encoding for level 1
      level1_encoded_stage4 <= {7'b0, level1_pending_stage3[0]} | 
                              {6'b0, level1_pending_stage3[1], 1'b0} | 
                              {5'b0, level1_pending_stage3[2], 2'b0} | 
                              {4'b0, level1_pending_stage3[3], 3'b0} | 
                              {3'b0, level1_pending_stage3[4], 4'b0} | 
                              {2'b0, level1_pending_stage3[5], 5'b0} | 
                              {1'b0, level1_pending_stage3[6], 6'b0} | 
                              {level1_pending_stage3[7], 7'b0};
      
      // LSB-first priority encoding for level 2
      level2_encoded_stage4 <= {7'b0, level2_pending_stage3[0]} | 
                              {6'b0, level2_pending_stage3[1], 1'b0} | 
                              {5'b0, level2_pending_stage3[2], 2'b0} | 
                              {4'b0, level2_pending_stage3[3], 3'b0} | 
                              {3'b0, level2_pending_stage3[4], 4'b0} | 
                              {2'b0, level2_pending_stage3[5], 5'b0} | 
                              {1'b0, level2_pending_stage3[6], 6'b0} | 
                              {level2_pending_stage3[7], 7'b0};
      
      // LSB-first priority encoding for level 3
      level3_encoded_stage4 <= {7'b0, level3_pending_stage3[0]} | 
                              {6'b0, level3_pending_stage3[1], 1'b0} | 
                              {5'b0, level3_pending_stage3[2], 2'b0} | 
                              {4'b0, level3_pending_stage3[3], 3'b0} | 
                              {3'b0, level3_pending_stage3[4], 4'b0} | 
                              {2'b0, level3_pending_stage3[5], 5'b0} | 
                              {1'b0, level3_pending_stage3[6], 6'b0} | 
                              {level3_pending_stage3[7], 7'b0};
      
      // Stage 5: Select final priority level and encode
      pending_stage5 <= pending_stage4;
      ack_stage5 <= ack_stage4;
      intr_id_stage5 <= intr_id_stage4;
      valid_stage5 <= valid_stage4;
      
      // Final priority level selection
      if (|level0_encoded_stage4) begin
        final_encoded_stage5 <= level0_encoded_stage4;
        selected_level_stage5 <= 2'b00;
      end else if (|level1_encoded_stage4) begin
        final_encoded_stage5 <= level1_encoded_stage4;
        selected_level_stage5 <= 2'b01;
      end else if (|level2_encoded_stage4) begin
        final_encoded_stage5 <= level2_encoded_stage4;
        selected_level_stage5 <= 2'b10;
      end else begin
        final_encoded_stage5 <= level3_encoded_stage4;
        selected_level_stage5 <= 2'b11;
      end
      
      // Stage 6 (Output stage): Generate outputs
      intr_id <= onehot_to_binary(final_encoded_stage5);
      intr_valid <= |final_encoded_stage5;
    end
  end
  
endmodule