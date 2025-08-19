//SystemVerilog
module weighted_rr_arbiter(
  input clk, rst,
  input [2:0] req,
  input [1:0] weights [2:0],  // Weight for each requester
  output reg [2:0] grant
);
  reg [2:0] count [2:0];  // Counter for each requester
  reg [1:0] current;      // Current requester being served
  
  // Reset logic
  always @(posedge clk) begin
    if (rst) begin
      current <= 0;
      grant <= 0;
      count[0] <= 0; 
      count[1] <= 0; 
      count[2] <= 0;
    end
  end
  
  // Grant generation logic
  always @(posedge clk) begin
    if (!rst) begin
      grant <= 0;  // Default grant
      if (req[current] && count[current] < weights[current]) begin
        grant[current] <= 1'b1;
      end
    end
  end
  
  // Counter management logic with Brent-Kung adder
  always @(posedge clk) begin
    if (!rst) begin
      if (req[current] && count[current] < weights[current]) begin
        count[current] <= brent_kung_adder(count[current], 3'b001);
      end else begin
        count[current] <= 0;
      end
    end
  end
  
  // Current requester pointer update logic
  always @(posedge clk) begin
    if (!rst) begin
      if (!(req[current] && count[current] < weights[current])) begin
        current <= (current + 1) % 3;
      end
    end
  end
  
  // Brent-Kung adder for 3-bit addition
  function [2:0] brent_kung_adder;
    input [2:0] a;
    input [2:0] b;
    
    reg [2:0] sum;
    reg [2:0] p; // Propagate signals
    reg [2:0] g; // Generate signals
    reg [2:0] c; // Carry signals
    
    begin
      // Step 1: Generate propagate and generate signals
      p = a ^ b;
      g = a & b;
      
      // Step 2: Compute carries using Brent-Kung tree structure
      // First level
      c[0] = 0; // Carry-in is 0
      
      // Second level (Group propagate and generate)
      c[1] = g[0] | (p[0] & c[0]);
      
      // Third level
      c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
      
      // Step 3: Compute sum
      sum = p ^ {c[2:0]};
      
      brent_kung_adder = sum;
    end
  endfunction
endmodule