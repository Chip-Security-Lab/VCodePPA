//SystemVerilog - IEEE 1364-2005
`timescale 1ns / 1ps
`default_nettype none

module barrel_arbiter #(parameter CLIENTS=8) (
  input wire clk, rst,
  input wire [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants,
  output reg [$clog2(CLIENTS)-1:0] position
);
  reg [CLIENTS-1:0] rotated_req;
  reg [CLIENTS-1:0] rotated_grant;
  reg [$clog2(CLIENTS)-1:0] pos_next;
  reg [CLIENTS-1:0] first_one_hot;
  reg [$clog2(CLIENTS)-1:0] offset;
  
  // Optimized priority logic using simplified bit operations
  always @(*) begin
    // Rotate request vector based on current position
    rotated_req = (requests >> position) | (requests << (CLIENTS - position));
    rotated_grant = {CLIENTS{1'b0}};
    pos_next = position;
    
    // Find first requesting client - simplified rightmost '1' isolation
    first_one_hot = rotated_req & (-rotated_req); // More efficient than (~masked_req + 1'b1)
    
    // Update position and grant when at least one request exists
    if (|rotated_req) begin
      rotated_grant = first_one_hot;
      
      // Directly compute position offset using priority encoder pattern
      offset = 0;
      for (int i = 0; i < CLIENTS; i++) begin
        if (first_one_hot[i]) begin
          offset = i;
        end
      end
      
      // Calculate next position with single operation
      pos_next = (position + offset + 1) % CLIENTS;
    end
    
    // Un-rotate grants using optimized approach
    grants = {CLIENTS{1'b0}};
    for (int i = 0; i < CLIENTS; i++) begin
      if (rotated_grant[i])
        grants[(i + position) % CLIENTS] = 1'b1;
    end
  end
  
  // Sequential logic for position update
  always @(posedge clk) begin
    if (rst)
      position <= {$clog2(CLIENTS){1'b0}};
    else
      position <= pos_next;
  end
endmodule