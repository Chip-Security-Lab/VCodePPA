//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_sync_handshake_axi (
  input  wire        aclk,           // Clock input
  input  wire        aresetn,        // Active low reset
  
  // AXI-Stream Slave interface (input)
  input  wire        s_axis_tvalid,  // Input data valid
  output wire        s_axis_tready,  // Ready to accept data
  input  wire [0:0]  s_axis_tdata,   // Input data (reset valid signal)
  
  // AXI-Stream Master interface (output)
  output reg         m_axis_tvalid,  // Output data valid
  input  wire        m_axis_tready,  // Downstream ready
  output reg  [0:0]  m_axis_tdata,   // Output data (reset done signal)
  output reg         m_axis_tlast    // Indicates last transaction
);

  // Internal signals
  reg sync_flop;
  reg handshake_complete;
  
  // Internal control signals and registered inputs
  reg s_axis_tvalid_reg;
  reg [0:0] s_axis_tdata_reg;
  reg generate_output;
  reg handshake_in_progress;
  
  // AXI-Stream slave interface always ready to accept data
  assign s_axis_tready = 1'b1;
  
  // Reset synchronization logic with AXI-Stream handshaking
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      // Initialize all registers on reset
      s_axis_tvalid_reg  <= 1'b0;
      s_axis_tdata_reg   <= 1'b0;
      sync_flop          <= 1'b0;
      m_axis_tdata[0]    <= 1'b0;
      m_axis_tvalid      <= 1'b0;
      m_axis_tlast       <= 1'b0;
      handshake_complete <= 1'b0;
      generate_output    <= 1'b0;
      handshake_in_progress <= 1'b0;
    end 
    else begin
      // Register input signals first (moving registers forward)
      s_axis_tvalid_reg <= s_axis_tvalid && s_axis_tready;
      s_axis_tdata_reg <= s_axis_tdata;
      
      // Combined detection and sync_flop update
      if (s_axis_tvalid_reg && s_axis_tdata_reg[0] && !sync_flop && !handshake_complete) begin
        sync_flop <= 1'b1;
        generate_output <= 1'b1;
      end else begin
        generate_output <= 1'b0;
      end
      
      // Generate output when ready
      if (generate_output) begin
        m_axis_tvalid <= 1'b1;
        m_axis_tdata[0] <= 1'b1;
        m_axis_tlast <= 1'b1;
        handshake_in_progress <= 1'b1;
      end
      
      // Handle completion of AXI handshake
      if (m_axis_tvalid && m_axis_tready) begin
        handshake_complete <= 1'b1;
        m_axis_tvalid <= 1'b0;
        handshake_in_progress <= 1'b0;
      end
    end
  end
  
endmodule