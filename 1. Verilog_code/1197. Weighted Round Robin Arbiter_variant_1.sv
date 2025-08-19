//SystemVerilog
module weighted_rr_arbiter(
  input wire clk,
  input wire rst,
  input wire [2:0] req,
  input wire [1:0] weights [2:0],  // Weight for each requester
  output reg [2:0] grant,
  // Pipeline control signals
  input wire ready_in,
  output reg valid_out
);
  // Pipeline stages
  // Stage 1: Request handling and counter management
  reg [2:0] req_stage1;
  reg [1:0] weights_stage1 [2:0];
  reg [2:0] count_stage1 [2:0];
  reg [1:0] current_stage1;
  reg valid_stage1;
  
  // Stage 2: Grant generation
  reg [2:0] req_stage2;
  reg [1:0] current_stage2;
  reg [2:0] count_stage2 [2:0];
  reg [1:0] weights_stage2 [2:0];
  reg valid_stage2;
  
  // Intermediate signals for decision tree
  wire current_req_active;
  wire current_count_valid;
  wire need_to_change_requester;
  reg [1:0] next_current;
  
  // Decision tree intermediate signals
  assign current_req_active = req[current_stage1];
  assign current_count_valid = count_stage1[current_stage1] < weights_stage1[current_stage1];
  assign need_to_change_requester = !current_req_active || !current_count_valid;
  
  // Calculate next requester using priority logic
  always @(*) begin
    case (current_stage1)
      2'd0: next_current = 2'd1;
      2'd1: next_current = 2'd2;
      2'd2: next_current = 2'd0;
      default: next_current = 2'd0;
    endcase
  end
  
  // Stage 1: Request handling and arbiter state update
  always @(posedge clk) begin
    if (rst) begin
      current_stage1 <= 0;
      req_stage1 <= 0;
      count_stage1[0] <= 0; 
      count_stage1[1] <= 0; 
      count_stage1[2] <= 0;
      weights_stage1[0] <= 0; 
      weights_stage1[1] <= 0; 
      weights_stage1[2] <= 0;
      valid_stage1 <= 0;
    end else if (ready_in) begin
      req_stage1 <= req;
      weights_stage1[0] <= weights[0];
      weights_stage1[1] <= weights[1];
      weights_stage1[2] <= weights[2];
      valid_stage1 <= 1'b1;
      
      // Decision tree for counter and current requester update
      if (need_to_change_requester) begin
        // Reset counter and move to next requester
        count_stage1[current_stage1] <= 0;
        current_stage1 <= next_current;
      end else begin
        // Increment counter for current requester
        count_stage1[current_stage1] <= count_stage1[current_stage1] + 1'b1;
      end
    end
  end
  
  // Stage 2: Pipeline registers
  always @(posedge clk) begin
    if (rst) begin
      req_stage2 <= 0;
      current_stage2 <= 0;
      count_stage2[0] <= 0; 
      count_stage2[1] <= 0; 
      count_stage2[2] <= 0;
      weights_stage2[0] <= 0; 
      weights_stage2[1] <= 0; 
      weights_stage2[2] <= 0;
      valid_stage2 <= 0;
    end else begin
      req_stage2 <= req_stage1;
      current_stage2 <= current_stage1;
      count_stage2[0] <= count_stage1[0];
      count_stage2[1] <= count_stage1[1];
      count_stage2[2] <= count_stage1[2];
      weights_stage2[0] <= weights_stage1[0];
      weights_stage2[1] <= weights_stage1[1];
      weights_stage2[2] <= weights_stage1[2];
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Output stage: Decision tree for grant generation
  reg grant_valid;
  reg [1:0] grant_index;
  
  always @(*) begin
    grant_valid = valid_stage2 && req_stage2[current_stage2] && 
                 (count_stage2[current_stage2] < weights_stage2[current_stage2]);
    grant_index = current_stage2;
  end
  
  always @(posedge clk) begin
    if (rst) begin
      grant <= 0;
      valid_out <= 0;
    end else begin
      grant <= 0;
      if (grant_valid) begin
        grant[grant_index] <= 1'b1;
      end
      valid_out <= valid_stage2;
    end
  end
endmodule