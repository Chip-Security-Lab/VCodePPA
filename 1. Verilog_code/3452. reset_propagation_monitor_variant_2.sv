//SystemVerilog
module reset_propagation_monitor (
  input wire clk,
  input wire reset_src,
  input wire [3:0] reset_dst,
  output reg propagation_error
);
  reg reset_src_d;
  reg [7:0] timeout;
  reg checking;
  
  // Brent-Kung adder signals
  wire [7:0] next_timeout;
  wire [7:0] a, b;
  wire [7:0] p, g; // Propagate and generate signals
  wire [7:0] c; // Carry signals
  
  // Input assignment
  assign a = timeout;
  assign b = 8'd1;
  
  // Generate propagate and generate signals
  assign p = a ^ b;
  assign g = a & b;
  
  // First level of prefix computation
  wire [3:0] p_lvl1, g_lvl1;
  assign p_lvl1[0] = p[1] & p[0];
  assign g_lvl1[0] = g[1] | (p[1] & g[0]);
  assign p_lvl1[1] = p[3] & p[2];
  assign g_lvl1[1] = g[3] | (p[3] & g[2]);
  assign p_lvl1[2] = p[5] & p[4];
  assign g_lvl1[2] = g[5] | (p[5] & g[4]);
  assign p_lvl1[3] = p[7] & p[6];
  assign g_lvl1[3] = g[7] | (p[7] & g[6]);
  
  // Second level of prefix computation
  wire [1:0] p_lvl2, g_lvl2;
  assign p_lvl2[0] = p_lvl1[1] & p_lvl1[0];
  assign g_lvl2[0] = g_lvl1[1] | (p_lvl1[1] & g_lvl1[0]);
  assign p_lvl2[1] = p_lvl1[3] & p_lvl1[2];
  assign g_lvl2[1] = g_lvl1[3] | (p_lvl1[3] & g_lvl1[2]);
  
  // Third level of prefix computation
  wire p_lvl3, g_lvl3;
  assign p_lvl3 = p_lvl2[1] & p_lvl2[0];
  assign g_lvl3 = g_lvl2[1] | (p_lvl2[1] & g_lvl2[0]);
  
  // Carry computation
  assign c[0] = g[0];
  assign c[1] = g_lvl1[0];
  assign c[2] = g[2] | (p[2] & g_lvl1[0]);
  assign c[3] = g_lvl2[0];
  assign c[4] = g[4] | (p[4] & g_lvl2[0]);
  assign c[5] = g_lvl1[2] | (p_lvl1[2] & g_lvl2[0]);
  assign c[6] = g[6] | (p[6] & (g_lvl1[2] | (p_lvl1[2] & g_lvl2[0])));
  assign c[7] = g_lvl3;
  
  // Sum computation
  assign next_timeout[0] = p[0];
  assign next_timeout[7:1] = p[7:1] ^ c[6:0];

  always @(posedge clk) begin
    reset_src_d <= reset_src;
    
    if (reset_src && !reset_src_d) begin
      // Reset edge detected - start checking
      checking <= 1'b1;
      timeout <= 8'd0;
      propagation_error <= 1'b0;
    end 
    else if (checking) begin
      // Increment timeout counter while checking using Brent-Kung adder
      timeout <= next_timeout;
      
      // Priority checking for completion conditions
      if (&reset_dst) begin
        // All destination resets are active - propagation complete
        checking <= 1'b0;
      end
      else if (timeout >= 8'hFE) begin
        // Timeout reached - set error and stop checking
        propagation_error <= 1'b1;
        checking <= 1'b0;
      end
    end
  end
endmodule