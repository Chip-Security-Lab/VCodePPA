//SystemVerilog
// Top-level module
module edge_reset_monitor (
  input  wire clk,
  input  wire reset_n,
  output wire reset_edge_detected
);
  
  // Internal signals for interconnection
  wire reset_n_delayed;
  
  // Clock buffering for different submodules
  wire clk_delay;
  wire clk_detector;
  
  // Clock buffer instances
  clk_buffer u_clk_buffer_delay (
    .clk_in  (clk),
    .clk_out (clk_delay)
  );
  
  clk_buffer u_clk_buffer_detector (
    .clk_in  (clk),
    .clk_out (clk_detector)
  );
  
  // Submodule instantiations with buffered clocks
  reset_signal_delay u_delay (
    .clk           (clk_delay),
    .reset_n_in    (reset_n),
    .reset_n_out   (reset_n_delayed)
  );
  
  edge_detector u_detector (
    .clk           (clk_detector),
    .signal_in     (reset_n),
    .signal_delayed(reset_n_delayed),
    .edge_detected (reset_edge_detected)
  );

endmodule

// Clock buffer module
module clk_buffer (
  input  wire clk_in,
  output wire clk_out
);
  
  // Simple non-inverting buffer
  assign clk_out = clk_in;
  
  // Synthesis attributes to prevent optimization
  // synthesis attribute keep of clk_out is "true"
  // synthesis attribute dont_touch of clk_out is "true"
  
endmodule

// Reset signal delay submodule
module reset_signal_delay (
  input  wire clk,
  input  wire reset_n_in,
  output reg  reset_n_out
);
  
  always @(posedge clk) begin
    reset_n_out <= reset_n_in;
  end
  
endmodule

// Edge detection submodule
module edge_detector (
  input  wire clk,
  input  wire signal_in,
  input  wire signal_delayed,
  output reg  edge_detected
);
  
  always @(posedge clk) begin
    edge_detected <= ~signal_in & signal_delayed;
  end
  
endmodule