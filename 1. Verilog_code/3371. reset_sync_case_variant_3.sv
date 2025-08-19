//SystemVerilog
module reset_sync_axi(
  input  wire        aclk,           // Clock
  input  wire        aresetn,        // Active low reset
  
  // AXI-Stream Slave Interface
  input  wire        s_axis_tvalid,  // Slave valid signal
  output wire        s_axis_tready,  // Slave ready signal
  input  wire [0:0]  s_axis_tdata,   // Slave data (1-bit)
  
  // AXI-Stream Master Interface
  output reg         m_axis_tvalid,  // Master valid signal
  input  wire        m_axis_tready,  // Master ready signal
  output reg  [0:0]  m_axis_tdata,   // Master data (1-bit)
  output reg         m_axis_tlast    // Last signal (indicates end of reset sequence)
);

  // Internal signals - use 2-bit shift register for synchronization
  reg [1:0] sync_stages;
  wire reset_complete;
  
  // Always accept input data when not in reset
  assign s_axis_tready = aresetn;
  
  // Derive reset_complete from the synchronization stages
  assign reset_complete = sync_stages[1];
  
  // Reset synchronization logic with optimized structure
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      sync_stages <= 2'b00;
      m_axis_tvalid <= 1'b0;
      m_axis_tdata <= 1'b0;
      m_axis_tlast <= 1'b0;
    end else begin
      // Shift register for reset synchronization
      sync_stages <= {sync_stages[0], 1'b1};
      
      // Drive AXI-Stream master interface directly from reset_complete
      m_axis_tvalid <= reset_complete;
      m_axis_tdata <= reset_complete;
      
      // Optimize TLAST logic with direct comparison
      if (reset_complete && m_axis_tready && !m_axis_tlast)
        m_axis_tlast <= 1'b1;
    end
  end
  
endmodule