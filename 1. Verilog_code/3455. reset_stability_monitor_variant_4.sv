//SystemVerilog
module reset_stability_monitor (
  // Clock and reset
  input  wire        clk,
  input  wire        reset_n,
  
  // AXI-Stream output interface
  output wire [3:0]  m_axis_tdata,
  output reg         m_axis_tvalid,
  input  wire        m_axis_tready,
  output reg         m_axis_tlast
);
  
  reg reset_prev;
  reg [3:0] glitch_counter;
  reg reset_unstable_pre; // Intermediate signal
  reg reset_unstable;     // Moved register
  
  // Move reset_prev register after the comparison logic
  wire reset_changed = (reset_n != reset_prev);
  
  // Monitor reset stability with optimized timing
  always @(posedge clk) begin
    reset_prev <= reset_n;
    
    if (reset_changed) begin
      glitch_counter <= glitch_counter + 1;
    end
    
    // Pre-compute unstable condition
    reset_unstable_pre <= (glitch_counter > 4'd5);
    
    // Register the final unstable status (moved forward)
    reset_unstable <= reset_unstable_pre;
  end
  
  // AXI-Stream interface logic
  always @(posedge clk) begin
    if (!reset_n) begin
      m_axis_tvalid <= 1'b0;
      m_axis_tlast  <= 1'b0;
    end else begin
      // Assert valid when unstable status changes
      if (reset_unstable) begin
        m_axis_tvalid <= 1'b1;
        // Assert tlast to indicate end of transaction
        m_axis_tlast  <= 1'b1;
      end else if (m_axis_tready && m_axis_tvalid) begin
        // Clear valid after handshake complete
        m_axis_tvalid <= 1'b0;
        m_axis_tlast  <= 1'b0;
      end
    end
  end
  
  // Connect glitch counter to TDATA
  assign m_axis_tdata = glitch_counter;
  
endmodule