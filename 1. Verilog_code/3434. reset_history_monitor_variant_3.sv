//SystemVerilog
module reset_history_monitor (
  input wire clk,
  input wire reset_in,
  input wire clear,
  output reg [7:0] reset_history
);
  reg reset_in_d1;
  reg reset_in_d2;
  wire reset_edge_detected;
  
  // Optimize edge detection by moving to a separate combinational logic
  assign reset_edge_detected = reset_in_d1 && !reset_in_d2;
  
  always @(posedge clk) begin
    // Pipeline input registration
    reset_in_d1 <= reset_in;
    reset_in_d2 <= reset_in_d1;
    
    // Simplified conditional logic with priority encoding
    if (clear)
      reset_history <= 8'h00;
    else if (reset_edge_detected)
      reset_history <= {reset_history[6:0], 1'b1};
  end
endmodule