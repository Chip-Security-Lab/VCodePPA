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
  reg pre_propagation_error;
  
  // Optimize edge detection and condition checks
  wire reset_start = reset_src & ~reset_src_d;
  wire reset_complete = &reset_dst[3:0];
  wire timeout_expired = (timeout >= 8'hFF);

  always @(posedge clk) begin
    // Edge detection register
    reset_src_d <= reset_src;
    
    // State machine with optimized comparison chain
    if (reset_start) begin
      // Reset condition - initialize monitoring
      checking <= 1'b1;
      timeout <= 8'd0;
      pre_propagation_error <= 1'b0;
    end 
    else if (checking) begin
      // Combined condition checks with prioritized evaluations
      if (reset_complete) begin
        // Early success condition - higher priority
        checking <= 1'b0;
      end
      else if (timeout_expired) begin
        // Failure condition - lower priority
        pre_propagation_error <= 1'b1;
        checking <= 1'b0;
      end
      else begin
        // Continue counting only if still checking
        timeout <= timeout + 8'd1;
      end
    end
  end
  
  // Output stage
  always @(posedge clk) begin
    propagation_error <= pre_propagation_error;
  end
endmodule