//SystemVerilog
module async_reset_status (
  input wire clk,
  input wire reset,
  output wire reset_active,
  output reg [3:0] reset_count
);
  // Direct assignment for reset status signal
  assign reset_active = reset;
  
  // Internal signals for carry-lookahead adder
  wire [3:0] p, g;
  wire [4:0] c;
  wire [3:0] next_count;
  
  // Generate propagate and generate signals
  assign p = reset_count | 4'b0001; // Propagate
  assign g = reset_count & 4'b0001; // Generate
  
  // Carry calculation using lookahead logic
  assign c[0] = 1'b0;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
  
  // Sum calculation
  assign next_count = p ^ c[3:0];
  
  // Optimized counter with asynchronous reset
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Clear counter on reset
      reset_count <= 4'b0000;
    end
    else if (reset_count != 4'b1111) begin
      // Increment counter using CLA adder until maximum value
      reset_count <= next_count;
    end
    // Implicit else: hold maximum value
  end
endmodule