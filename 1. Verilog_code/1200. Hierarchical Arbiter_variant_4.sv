//SystemVerilog
module hierarchical_arbiter(
  input clk, rst_n,
  input [7:0] requests,
  output reg [7:0] grants,
  output reg valid_out
);
  // Stage 1 registers
  reg [7:0] requests_stage1;
  reg [1:0] group_reqs_stage1;
  reg valid_stage1;
  
  // Stage 2 registers
  reg [7:0] requests_stage2;
  reg [1:0] group_reqs_stage2;
  reg [1:0] group_grants_stage2;
  reg valid_stage2;
  
  // Stage 3 registers
  reg [3:0] sub_grants_0_stage3;
  reg [3:0] sub_grants_1_stage3;
  reg valid_stage3;
  
  // Stage 1: Calculate group requests
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      requests_stage1 <= 8'h00;
      group_reqs_stage1 <= 2'b00;
      valid_stage1 <= 1'b0;
    end
    else begin
      requests_stage1 <= requests;
      group_reqs_stage1[0] <= |requests[3:0];
      group_reqs_stage1[1] <= |requests[7:4];
      valid_stage1 <= 1'b1;
    end
  end
  
  // Stage 2: Perform top-level arbitration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      requests_stage2 <= 8'h00;
      group_reqs_stage2 <= 2'b00;
      group_grants_stage2 <= 2'b00;
      valid_stage2 <= 1'b0;
    end
    else begin
      requests_stage2 <= requests_stage1;
      group_reqs_stage2 <= group_reqs_stage1;
      
      // Top-level arbiter logic
      group_grants_stage2[0] <= group_reqs_stage1[0] & ~group_reqs_stage1[1];
      group_grants_stage2[1] <= group_reqs_stage1[1];
      
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Stage 3: Perform sub-arbitration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sub_grants_0_stage3 <= 4'b0000;
      sub_grants_1_stage3 <= 4'b0000;
      valid_stage3 <= 1'b0;
    end
    else begin
      // Default values
      sub_grants_0_stage3 <= 4'b0000;
      sub_grants_1_stage3 <= 4'b0000;
      
      // Sub-arbiter 0 logic - using case statement
      if (group_grants_stage2[0]) begin
        case (1'b1)
          requests_stage2[0]: sub_grants_0_stage3[0] <= 1'b1;
          requests_stage2[1]: sub_grants_0_stage3[1] <= 1'b1;
          requests_stage2[2]: sub_grants_0_stage3[2] <= 1'b1;
          requests_stage2[3]: sub_grants_0_stage3[3] <= 1'b1;
          default: sub_grants_0_stage3 <= 4'b0000;
        endcase
      end
      
      // Sub-arbiter 1 logic - using case statement
      if (group_grants_stage2[1]) begin
        case (1'b1)
          requests_stage2[4]: sub_grants_1_stage3[0] <= 1'b1;
          requests_stage2[5]: sub_grants_1_stage3[1] <= 1'b1;
          requests_stage2[6]: sub_grants_1_stage3[2] <= 1'b1;
          requests_stage2[7]: sub_grants_1_stage3[3] <= 1'b1;
          default: sub_grants_1_stage3 <= 4'b0000;
        endcase
      end
      
      valid_stage3 <= valid_stage2;
    end
  end
  
  // Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grants <= 8'h00;
      valid_out <= 1'b0;
    end
    else begin
      grants <= {sub_grants_1_stage3, sub_grants_0_stage3};
      valid_out <= valid_stage3;
    end
  end
endmodule