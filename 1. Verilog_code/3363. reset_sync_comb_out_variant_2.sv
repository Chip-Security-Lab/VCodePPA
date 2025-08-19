//SystemVerilog
module reset_sync_comb_out (
  input  wire        clk,            // Clock input
  input  wire        rst_in,         // Asynchronous reset input
  
  // AXI-Stream slave interface
  input  wire        s_axis_tvalid,  // Input valid signal
  output wire        s_axis_tready,  // Ready to accept input
  input  wire [0:0]  s_axis_tdata,   // Input data (using 1-bit as minimal width)
  
  // AXI-Stream master interface
  output wire        m_axis_tvalid,  // Output valid signal
  input  wire        m_axis_tready,  // Downstream is ready
  output wire [0:0]  m_axis_tdata,   // Output reset status
  output wire        m_axis_tlast    // Indicates end of transfer
);

  //============================================================
  // Reset Synchronization Pipeline
  //============================================================
  // First synchronization stage
  reg reset_sync_stage1;
  // Second synchronization stage
  reg reset_sync_stage2;
  // Valid status register
  reg reset_valid_status;
  
  //============================================================
  // Reset Synchronization Process
  //============================================================
  always @(posedge clk or negedge rst_in) begin
    if (!rst_in) begin
      // Reset state initialization
      reset_sync_stage1  <= 1'b0;
      reset_sync_stage2  <= 1'b0;
      reset_valid_status <= 1'b0;
    end 
    else begin
      // Normal operation state progression
      reset_sync_stage1  <= 1'b1;
      reset_sync_stage2  <= reset_sync_stage1;
      reset_valid_status <= 1'b1;
    end
  end
  
  //============================================================
  // Data Flow Control Signals
  //============================================================
  // Synchronized reset output signal
  wire synchronized_reset = reset_sync_stage1 & reset_sync_stage2;
  
  // Pipeline registers for AXI stream control
  reg  input_valid_reg;
  reg  output_ready_reg;
  reg  [0:0] data_reg;
  
  //============================================================
  // AXI Stream Control Pipeline
  //============================================================
  always @(posedge clk or negedge rst_in) begin
    if (!rst_in) begin
      input_valid_reg  <= 1'b0;
      output_ready_reg <= 1'b0;
      data_reg         <= 1'b0;
    end
    else begin
      input_valid_reg  <= s_axis_tvalid;
      output_ready_reg <= m_axis_tready;
      data_reg         <= synchronized_reset;
    end
  end
  
  //============================================================
  // AXI Stream Interface Outputs
  //============================================================
  // Handshaking signals with proper timing relationships
  assign s_axis_tready = output_ready_reg | ~input_valid_reg;
  assign m_axis_tvalid = reset_valid_status & input_valid_reg;
  
  // Data path signals
  assign m_axis_tdata  = data_reg;
  assign m_axis_tlast  = 1'b1;  // Each transfer is complete
  
endmodule