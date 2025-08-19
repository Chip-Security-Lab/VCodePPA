//SystemVerilog
module daisy_chain_intr_ctrl(
  input clk, rst_n,
  input [3:0] requests,
  input chain_in,
  output reg [1:0] local_id,
  output chain_out,
  output reg grant
);
  // Stage 1 signals
  reg local_req_stage1;
  reg [1:0] local_id_stage1;
  reg chain_in_stage1;
  
  // Stage 2 signals
  reg local_req_stage2;
  reg chain_in_stage2;
  reg [1:0] local_id_stage2;
  
  // Pipeline stage 1: Request detection and priority encoding
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      local_req_stage1 <= 1'b0;
      local_id_stage1 <= 2'd0;
      chain_in_stage1 <= 1'b0;
    end
    else begin
      local_req_stage1 <= |requests;
      chain_in_stage1 <= chain_in;
      
      casez (requests)
        4'b???1: local_id_stage1 <= 2'd0;
        4'b??10: local_id_stage1 <= 2'd1;
        4'b?100: local_id_stage1 <= 2'd2;
        4'b1000: local_id_stage1 <= 2'd3;
        default: local_id_stage1 <= 2'd0;
      endcase
    end
  end
  
  // Pipeline stage 2: Chain logic and grant generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      local_req_stage2 <= 1'b0;
      chain_in_stage2 <= 1'b0;
      local_id_stage2 <= 2'd0;
      grant <= 1'b0;
    end
    else begin
      local_req_stage2 <= local_req_stage1;
      chain_in_stage2 <= chain_in_stage1;
      local_id_stage2 <= local_id_stage1;
      grant <= local_req_stage1 & chain_in_stage1;
    end
  end
  
  // Output assignments
  assign chain_out = chain_in_stage2 & ~local_req_stage2;
  
  // Final output assignment
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      local_id <= 2'd0;
    end
    else begin
      local_id <= local_id_stage2;
    end
  end
endmodule