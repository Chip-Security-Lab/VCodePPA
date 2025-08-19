//SystemVerilog
module hierarchical_arbiter(
  input clock, reset,
  input [7:0] requests,
  output reg [7:0] grants
);
  wire [1:0] level1_req;
  reg [1:0] level1_grant;
  wire [3:0] upper_req, lower_req;
  wire [1:0] upper_pri, lower_pri;
  
  // Split requests into upper and lower groups
  assign upper_req = requests[7:4];
  assign lower_req = requests[3:0];
  
  // Priority encoding for each group
  assign upper_pri = {upper_req[3], upper_req[2] & ~upper_req[3]};
  assign lower_pri = {lower_req[3], lower_req[2] & ~lower_req[3]};
  
  // Hierarchical request aggregation
  assign level1_req = {|upper_req, |lower_req};
  
  always @(posedge clock) begin
    if (reset) begin
      level1_grant <= 2'b00;
      grants <= 8'b00000000;
    end else begin
      // Optimized priority selection
      level1_grant <= {level1_req[1], level1_req[0] & ~level1_req[1]};
      
      // Parallel grant generation
      grants <= level1_grant[1] ? {upper_pri, 4'b0} : 
               level1_grant[0] ? {4'b0, lower_pri} : 8'b0;
    end
  end
endmodule