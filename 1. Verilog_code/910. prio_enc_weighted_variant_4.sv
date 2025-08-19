//SystemVerilog
module prio_enc_weighted #(parameter N=4)(
  input clk,
  input [N-1:0] req,
  input [N-1:0] weight,
  output reg [1:0] max_idx
);

  reg [7:0] max_weight;
  reg [1:0] next_max_idx;
  reg [7:0] next_max_weight;
  
  // Parallel prefix subtractor signals
  wire [7:0] weight_diff_3_2;
  wire [7:0] weight_diff_1_0;
  wire [7:0] final_diff;
  wire [7:0] abs_diff_3_2;
  wire [7:0] abs_diff_1_0;
  wire [7:0] abs_final_diff;
  
  // Generate propagate and generate signals
  wire [7:0] p_3_2 = weight[3] ^ weight[2];
  wire [7:0] g_3_2 = weight[3] & ~weight[2];
  wire [7:0] p_1_0 = weight[1] ^ weight[0];
  wire [7:0] g_1_0 = weight[1] & ~weight[0];
  
  // First level of parallel prefix
  assign weight_diff_3_2 = p_3_2 & g_3_2;
  assign weight_diff_1_0 = p_1_0 & g_1_0;
  
  // Second level of parallel prefix
  wire [7:0] p_final = weight_diff_3_2 ^ weight_diff_1_0;
  wire [7:0] g_final = weight_diff_3_2 & ~weight_diff_1_0;
  assign final_diff = p_final & g_final;
  
  // Absolute value computation
  assign abs_diff_3_2 = weight_diff_3_2[7] ? ~weight_diff_3_2 + 1'b1 : weight_diff_3_2;
  assign abs_diff_1_0 = weight_diff_1_0[7] ? ~weight_diff_1_0 + 1'b1 : weight_diff_1_0;
  assign abs_final_diff = final_diff[7] ? ~final_diff + 1'b1 : final_diff;
  
  always @(*) begin
    next_max_weight = 8'b0;
    next_max_idx = 2'b0;
    
    // Parallel comparison using prefix results
    if (req[3] && req[2]) begin
      if (abs_diff_3_2[7] == 1'b0) begin
        next_max_weight = weight[3];
        next_max_idx = 2'd3;
      end else begin
        next_max_weight = weight[2];
        next_max_idx = 2'd2;
      end
    end else if (req[3]) begin
      next_max_weight = weight[3];
      next_max_idx = 2'd3;
    end else if (req[2]) begin
      next_max_weight = weight[2];
      next_max_idx = 2'd2;
    end
    
    if (req[1] && req[0]) begin
      if (abs_diff_1_0[7] == 1'b0) begin
        if (weight[1] > next_max_weight) begin
          next_max_weight = weight[1];
          next_max_idx = 2'd1;
        end
      end else begin
        if (weight[0] > next_max_weight) begin
          next_max_weight = weight[0];
          next_max_idx = 2'd0;
        end
      end
    end else if (req[1]) begin
      if (weight[1] > next_max_weight) begin
        next_max_weight = weight[1];
        next_max_idx = 2'd1;
      end
    end else if (req[0]) begin
      if (weight[0] > next_max_weight) begin
        next_max_weight = weight[0];
        next_max_idx = 2'd0;
      end
    end
  end
  
  always @(posedge clk) begin
    max_idx <= next_max_idx;
    max_weight <= next_max_weight;
  end
endmodule