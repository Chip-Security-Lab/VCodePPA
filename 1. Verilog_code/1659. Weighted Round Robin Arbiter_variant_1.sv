//SystemVerilog
module weighted_rr_arbiter(
  input wire clk, rst_b,
  input wire [3:0] req_vec,
  output reg [3:0] gnt_vec
);

  // Stage 1 registers
  reg [3:0] weights [0:3];
  reg [3:0] counters [0:3];
  reg [1:0] last_served_stage1;
  reg [3:0] req_vec_stage1;
  
  // Stage 2 registers
  reg [3:0] priority_mask_stage2;
  reg [3:0] valid_reqs_stage2;
  reg [3:0] selected_reqs_stage2;
  reg [1:0] last_served_stage2;
  reg [3:0] req_vec_stage2;
  
  // Stage 3 registers
  reg [1:0] next_served_stage3;
  reg [3:0] gnt_vec_stage3;
  reg [3:0] counters_stage3 [0:3];
  reg [1:0] last_served_stage3;

  // Stage 1 logic
  always @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
      weights[0] <= 4'd3;
      weights[1] <= 4'd2;
      weights[2] <= 4'd4;
      weights[3] <= 4'd1;
      counters[0] <= 4'd0;
      counters[1] <= 4'd0;
      counters[2] <= 4'd0;
      counters[3] <= 4'd0;
      last_served_stage1 <= 2'b0;
      req_vec_stage1 <= 4'b0;
    end else begin
      last_served_stage1 <= last_served_stage3;
      req_vec_stage1 <= req_vec;
    end
  end

  // Stage 2 logic
  always @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
      priority_mask_stage2 <= 4'b0;
      valid_reqs_stage2 <= 4'b0;
      selected_reqs_stage2 <= 4'b0;
      last_served_stage2 <= 2'b0;
      req_vec_stage2 <= 4'b0;
    end else begin
      priority_mask_stage2 <= 4'b1 << last_served_stage1;
      valid_reqs_stage2 <= req_vec_stage1 & priority_mask_stage2;
      selected_reqs_stage2 <= valid_reqs_stage2 | (req_vec_stage1 & ~priority_mask_stage2);
      last_served_stage2 <= last_served_stage1;
      req_vec_stage2 <= req_vec_stage1;
    end
  end

  // Stage 3 logic
  always @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
      next_served_stage3 <= 2'b0;
      gnt_vec_stage3 <= 4'b0;
      last_served_stage3 <= 2'b0;
      for (int i = 0; i < 4; i = i + 1) begin
        counters_stage3[i] <= 4'd0;
      end
    end else begin
      next_served_stage3 <= selected_reqs_stage2[0] ? 2'd0 :
                           selected_reqs_stage2[1] ? 2'd1 :
                           selected_reqs_stage2[2] ? 2'd2 :
                           selected_reqs_stage2[3] ? 2'd3 : last_served_stage2;
      
      if (|req_vec_stage2) begin
        gnt_vec_stage3 <= 4'b1 << next_served_stage3;
        last_served_stage3 <= next_served_stage3;
        
        for (int i = 0; i < 4; i = i + 1) begin
          if (gnt_vec_stage3[i]) begin
            counters_stage3[i] <= counters[i] + 1;
            if (counters[i] >= weights[i]) begin
              counters_stage3[i] <= 4'd0;
            end
          end
        end
      end else begin
        gnt_vec_stage3 <= 4'b0;
      end
    end
  end

  // Output assignment
  assign gnt_vec = gnt_vec_stage3;

endmodule