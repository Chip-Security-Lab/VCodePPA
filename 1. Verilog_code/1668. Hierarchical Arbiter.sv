module hierarchical_arbiter(
  input clock, reset,
  input [7:0] requests,
  output reg [7:0] grants
);
  wire [1:0] level1_req;
  reg [1:0] level1_grant;
  
  assign level1_req[0] = |requests[3:0];
  assign level1_req[1] = |requests[7:4];
  
  always @(posedge clock) begin
    if (reset) begin
      level1_grant <= 2'b00;
      grants <= 8'b00000000;
    end else begin
      // Level 1 arbitration
      level1_grant <= level1_req & ~(level1_req - 1);
      
      // Level 2 arbitration
      grants <= 8'b00000000;
      if (level1_grant[0]) grants[3:0] <= requests[3:0];
      if (level1_grant[1]) grants[7:4] <= requests[7:4];
    end
  end
endmodule