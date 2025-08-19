//SystemVerilog
module weighted_priority_intr_ctrl(
  input clk,
  input rst_n,
  input [7:0] interrupts,
  input [15:0] weights, // 2 bits per interrupt source
  output [2:0] priority_id,
  output req,          // 将valid改为req
  input ack            // 将ready改为ack
);
  reg [2:0] highest_id;
  reg [1:0] highest_weight;
  reg found;
  reg [2:0] priority_id_reg;
  reg req_reg;         // 将valid_reg改为req_reg
  
  // Stage 1: Check first half (0-3)
  reg [2:0] first_half_id;
  reg [1:0] first_half_weight;
  reg first_half_found;
  
  // Stage 2: Check second half (4-7)
  reg [2:0] second_half_id;
  reg [1:0] second_half_weight;
  reg second_half_found;
  
  // Stage 1.1: Check sources 0-1
  reg [2:0] pair0_id;
  reg [1:0] pair0_weight;
  reg pair0_found;
  
  // Stage 1.2: Check sources 2-3
  reg [2:0] pair1_id;
  reg [1:0] pair1_weight;
  reg pair1_found;
  
  // Stage 2.1: Check sources 4-5
  reg [2:0] pair2_id;
  reg [1:0] pair2_weight;
  reg pair2_found;
  
  // Stage 2.2: Check sources 6-7
  reg [2:0] pair3_id;
  reg [1:0] pair3_weight;
  reg pair3_found;
  
  // Determine the highest priority interrupt using a tree structure
  always @(*) begin
    // Base level comparisons - pairs of interrupts
    
    // Pair 0: Compare interrupts 0 and 1
    if (interrupts[0] && (!interrupts[1] || weights[1:0] >= weights[3:2])) begin
      pair0_id = 3'd0;
      pair0_weight = weights[1:0];
      pair0_found = interrupts[0];
    end else begin
      pair0_id = 3'd1;
      pair0_weight = weights[3:2];
      pair0_found = interrupts[1];
    end
    
    // Pair 1: Compare interrupts 2 and 3
    if (interrupts[2] && (!interrupts[3] || weights[5:4] >= weights[7:6])) begin
      pair1_id = 3'd2;
      pair1_weight = weights[5:4];
      pair1_found = interrupts[2];
    end else begin
      pair1_id = 3'd3;
      pair1_weight = weights[7:6];
      pair1_found = interrupts[3];
    end
    
    // Pair 2: Compare interrupts 4 and 5
    if (interrupts[4] && (!interrupts[5] || weights[9:8] >= weights[11:10])) begin
      pair2_id = 3'd4;
      pair2_weight = weights[9:8];
      pair2_found = interrupts[4];
    end else begin
      pair2_id = 3'd5;
      pair2_weight = weights[11:10];
      pair2_found = interrupts[5];
    end
    
    // Pair 3: Compare interrupts 6 and 7
    if (interrupts[6] && (!interrupts[7] || weights[13:12] >= weights[15:14])) begin
      pair3_id = 3'd6;
      pair3_weight = weights[13:12];
      pair3_found = interrupts[6];
    end else begin
      pair3_id = 3'd7;
      pair3_weight = weights[15:14];
      pair3_found = interrupts[7];
    end
    
    // Second level comparisons - compare pairs
    
    // First half: Compare pairs 0 and 1
    if (pair0_found && (!pair1_found || pair0_weight > pair1_weight)) begin
      first_half_id = pair0_id;
      first_half_weight = pair0_weight;
      first_half_found = 1'b1;
    end else if (pair1_found) begin
      first_half_id = pair1_id;
      first_half_weight = pair1_weight;
      first_half_found = 1'b1;
    end else begin
      first_half_id = 3'd0;
      first_half_weight = 2'd0;
      first_half_found = 1'b0;
    end
    
    // Second half: Compare pairs 2 and 3
    if (pair2_found && (!pair3_found || pair2_weight > pair3_weight)) begin
      second_half_id = pair2_id;
      second_half_weight = pair2_weight;
      second_half_found = 1'b1;
    end else if (pair3_found) begin
      second_half_id = pair3_id;
      second_half_weight = pair3_weight;
      second_half_found = 1'b1;
    end else begin
      second_half_id = 3'd0;
      second_half_weight = 2'd0;
      second_half_found = 1'b0;
    end
    
    // Final comparison: Compare first and second half
    if (first_half_found && (!second_half_found || first_half_weight > second_half_weight)) begin
      highest_id = first_half_id;
      highest_weight = first_half_weight;
      found = 1'b1;
    end else if (second_half_found) begin
      highest_id = second_half_id;
      highest_weight = second_half_weight;
      found = 1'b1;
    end else begin
      highest_id = 3'd0;
      highest_weight = 2'd0;
      found = 1'b0;
    end
  end
  
  // Req-Ack握手协议实现
  reg ack_prev;  // 用于检测ack信号的上升沿
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      priority_id_reg <= 3'd0;
      req_reg <= 1'b0;
      ack_prev <= 1'b0;
    end else begin
      ack_prev <= ack;
      
      if (!req_reg) begin
        // 没有活跃请求时，可以发起新请求
        if (found) begin
          priority_id_reg <= highest_id;
          req_reg <= 1'b1;
        end
      end else if (ack && !ack_prev) begin
        // 检测到ack信号的上升沿，表示请求被接收
        req_reg <= 1'b0;
      end
    end
  end
  
  assign priority_id = priority_id_reg;
  assign req = req_reg;
endmodule