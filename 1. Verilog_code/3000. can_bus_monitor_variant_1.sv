//SystemVerilog
module can_bus_monitor (
  // Clock and Reset
  input  wire        aclk,
  input  wire        aresetn,
  
  // CAN bus signals
  input  wire        can_rx,
  input  wire        can_tx,
  
  // AXI-Stream Slave Interface (Input)
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire [31:0] s_axis_tdata,
  input  wire        s_axis_tlast,
  
  // AXI-Stream Master Interface (Output)
  output reg         m_axis_tvalid,
  input  wire        m_axis_tready,
  output reg  [31:0] m_axis_tdata,
  output reg         m_axis_tlast
);

  // Internal signals
  reg  [15:0] frames_received;
  reg  [15:0] errors_detected;
  reg  [15:0] bus_load_percent;
  reg  [7:0]  last_error_type;
  reg  [31:0] total_bits, active_bits;
  
  // Extract signals from input AXI-Stream
  wire        frame_valid     = s_axis_tdata[0];
  wire        error_detected  = s_axis_tdata[1];
  wire [10:0] rx_id           = s_axis_tdata[12:2];
  wire [3:0]  rx_dlc          = s_axis_tdata[16:13];
  
  // Edge detection registers
  reg prev_frame_valid, prev_error;
  
  // Frame and error edge detection
  wire frame_edge = s_axis_tvalid && !prev_frame_valid && frame_valid;
  wire error_edge = s_axis_tvalid && !prev_error && error_detected;
  
  // Optimized bus load calculation signals
  wire bus_calc_required = (total_bits >= 32'd1000);
  
  // Always ready to receive data
  assign s_axis_tready = 1'b1;
  
  // Main processing logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      frames_received  <= 16'h0;
      errors_detected  <= 16'h0;
      bus_load_percent <= 16'h0;
      last_error_type  <= 8'h0;
      total_bits       <= 32'h0;
      active_bits      <= 32'h0;
      prev_frame_valid <= 1'b0;
      prev_error       <= 1'b0;
      m_axis_tvalid    <= 1'b0;
      m_axis_tdata     <= 32'h0;
      m_axis_tlast     <= 1'b0;
    end else begin
      // Default state for output signals
      m_axis_tvalid <= 1'b0;
      m_axis_tlast  <= 1'b0;
      
      // Update edge detection registers
      prev_frame_valid <= frame_valid;
      prev_error <= error_detected;
      
      // Count frames - optimized comparison logic
      if (frame_edge)
        frames_received <= frames_received + 16'h1;
        
      // Count errors - optimized comparison logic
      if (error_edge)
        errors_detected <= errors_detected + 16'h1;
      
      // Increment bit counters
      total_bits <= total_bits + 32'h1;
      active_bits <= active_bits + {31'h0, ~can_rx}; // Optimized conditional addition
      
      // Calculate bus load when threshold reached
      if (bus_calc_required) begin
        // Use optimized formula that avoids division when possible
        bus_load_percent <= ((active_bits << 7) / (total_bits >> 3));
        
        // Reset counters
        total_bits <= 32'h0;
        active_bits <= 32'h0;
        
        // Send output data
        m_axis_tvalid <= 1'b1;
        m_axis_tdata  <= {last_error_type, bus_load_percent, errors_detected, frames_received};
        m_axis_tlast  <= 1'b1;
      end
    end
  end
endmodule