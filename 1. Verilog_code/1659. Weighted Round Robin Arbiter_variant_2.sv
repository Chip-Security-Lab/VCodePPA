//SystemVerilog
module weighted_rr_arbiter(
  input wire clk,
  input wire rst_b,
  input wire [3:0] req_vec,
  output reg [3:0] gnt_vec
);

  // Weight configuration registers
  reg [3:0] weights [0:3];
  
  // Counter registers for each request
  reg [3:0] counters [0:3];
  
  // Last served request index
  reg [1:0] last_served;
  
  // Pipeline stage 1: Request qualification
  reg [3:0] qualified_req;
  reg [3:0] weight_accum [0:3];
  
  // Pipeline stage 2: Priority calculation
  reg [3:0] priority_vec;
  reg [1:0] next_served;

  always @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
      // Initialize weights
      weights[0] <= 4'd3;
      weights[1] <= 4'd2;
      weights[2] <= 4'd4;
      weights[3] <= 4'd1;
      
      // Reset pipeline stage 1
      qualified_req <= 4'b0;
      for (int i = 0; i < 4; i = i + 1) begin
        weight_accum[i] <= 4'b0;
      end
      
      // Reset pipeline stage 2
      priority_vec <= 4'b0;
      next_served <= 2'b0;
      gnt_vec <= 4'b0;
      last_served <= 2'b0;
      for (int i = 0; i < 4; i = i + 1) begin
        counters[i] <= 4'b0;
      end
    end else begin
      // Pipeline stage 1: Request qualification and weight accumulation
      qualified_req <= req_vec;
      for (int i = 0; i < 4; i = i + 1) begin
        weight_accum[i] <= (counters[i] < weights[i]) ? counters[i] + 1 : 4'b0;
      end
      
      // Pipeline stage 2: Priority calculation and grant generation
      priority_vec <= 4'b0;
      for (int i = 0; i < 4; i = i + 1) begin
        if (qualified_req[i] && weight_accum[i] > 0) begin
          priority_vec[i] <= 1'b1;
        end
      end

      gnt_vec <= 4'b0;
      for (int i = 0; i < 4; i = i + 1) begin
        if (priority_vec[i] && (i > last_served || !priority_vec[last_served])) begin
          gnt_vec[i] <= 1'b1;
          next_served <= i;
          counters[i] <= weight_accum[i];
        end
      end

      last_served <= next_served;
    end
  end

endmodule