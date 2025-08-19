module hierarchical_arbiter(
  input clk, rst_n,
  input [7:0] requests,
  output reg [7:0] grants
);
  reg [1:0] group_reqs;
  reg [1:0] group_grants;
  reg [3:0] sub_grants [0:1];
  
  always @(*) begin
    group_reqs[0] = |requests[3:0];
    group_reqs[1] = |requests[7:4];
  
    // Top-level arbiter
    group_grants[0] = group_reqs[0] & ~group_reqs[1];
    group_grants[1] = group_reqs[1];
  
    // Sub-arbiters
    sub_grants[0] = 4'b0000;
    sub_grants[1] = 4'b0000;
    
    if (group_grants[0]) begin
      if (requests[0]) sub_grants[0][0] = 1'b1;
      else if (requests[1]) sub_grants[0][1] = 1'b1;
      else if (requests[2]) sub_grants[0][2] = 1'b1;
      else if (requests[3]) sub_grants[0][3] = 1'b1;
    end
    
    if (group_grants[1]) begin
      if (requests[4]) sub_grants[1][0] = 1'b1;
      else if (requests[5]) sub_grants[1][1] = 1'b1;
      else if (requests[6]) sub_grants[1][2] = 1'b1;
      else if (requests[7]) sub_grants[1][3] = 1'b1;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) grants <= 8'h00;
    else grants <= {sub_grants[1], sub_grants[0]};
  end
endmodule