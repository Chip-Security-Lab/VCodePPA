//SystemVerilog
module can_ack_handler(
  // Clock and reset
  input  wire         aclk,
  input  wire         aresetn,
  
  // AXI-Stream input interface
  input  wire         s_axis_tvalid,
  output wire         s_axis_tready,
  input  wire [1:0]   s_axis_tdata,  // {can_rx, can_tx}
  input  wire [1:0]   s_axis_tuser,  // {in_ack_slot, in_ack_delim}
  
  // AXI-Stream output interface
  output wire         m_axis_tvalid,
  input  wire         m_axis_tready,
  output wire [1:0]   m_axis_tdata   // {ack_error, can_ack_drive}
);

  // Internal registers
  reg ack_error_reg;
  reg can_ack_drive_reg;
  
  // Input ready and output valid signals
  reg s_ready_reg;
  reg m_valid_reg;
  
  // Pipeline registers for input signals
  reg can_rx_reg, can_tx_reg;
  reg in_ack_slot_reg, in_ack_delim_reg;
  reg s_axis_tvalid_reg;
  
  // Extract signals from AXI-Stream interfaces
  wire can_rx, can_tx;
  wire in_ack_slot, in_ack_delim;
  
  assign can_rx = s_axis_tdata[0];
  assign can_tx = s_axis_tdata[1];
  assign in_ack_slot = s_axis_tuser[0];
  assign in_ack_delim = s_axis_tuser[1];
  
  // AXI handshaking
  assign s_axis_tready = s_ready_reg;
  assign m_axis_tvalid = m_valid_reg;
  assign m_axis_tdata = {ack_error_reg, can_ack_drive_reg};
  
  // Input registers - moving registers forward to reduce input timing path
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      can_rx_reg <= 1'b0;
      can_tx_reg <= 1'b0;
      in_ack_slot_reg <= 1'b0;
      in_ack_delim_reg <= 1'b0;
      s_axis_tvalid_reg <= 1'b0;
    end else if (s_axis_tvalid && s_ready_reg) begin
      can_rx_reg <= can_rx;
      can_tx_reg <= can_tx;
      in_ack_slot_reg <= in_ack_slot;
      in_ack_delim_reg <= in_ack_delim;
      s_axis_tvalid_reg <= s_axis_tvalid;
    end else if (m_axis_tready) begin
      s_axis_tvalid_reg <= 1'b0;
    end
  end
  
  // Input ready logic - always ready to accept new data
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_ready_reg <= 1'b1;
    end else begin
      s_ready_reg <= m_axis_tready || !m_valid_reg;
    end
  end
  
  // Core processing logic - now working with registered inputs
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      ack_error_reg <= 1'b0;
      can_ack_drive_reg <= 1'b0;
      m_valid_reg <= 1'b0;
    end else begin
      if (s_axis_tvalid_reg) begin
        // When receiving, drive ACK slot low (dominant)
        if (in_ack_slot_reg && !can_tx_reg) begin  // Only in receive mode
          can_ack_drive_reg <= 1'b1;
        end else begin
          can_ack_drive_reg <= 1'b0;
        end
        
        // When transmitting, check for ACK
        if (in_ack_slot_reg && can_tx_reg && can_rx_reg) begin
          ack_error_reg <= 1'b1;  // No acknowledgment received
        end else if (in_ack_delim_reg) begin
          ack_error_reg <= 1'b0;  // Reset for next frame
        end
        
        // Set valid when we have processed data
        m_valid_reg <= 1'b1;
      end else if (m_axis_tready) begin
        // Clear valid when handshake is complete
        m_valid_reg <= 1'b0;
      end
    end
  end
  
endmodule